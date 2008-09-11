#import "EnginesManager.h"
#import "EngineController.h"
#import "MessageProtocol.h"
#import "NSString+UUID.h"

@interface EnginesManager (Private)

- (void) netService:(NSNetService*)netService didNotResolve:(NSDictionary*)errorDict;
- (void) netService:(NSNetService*)netService didUpdateTXTRecordData:(NSData*)data;
- (void) netServiceDidResolveAddress:(NSNetService*)netService;

@end


@implementation EnginesManager
@synthesize localEngineID;

- (id) initWithManagedObjectContext:(NSManagedObjectContext*)_managedObjectContext 
{
    if (self = [super init]) {
        engineControllers = [[NSMutableDictionary alloc] init];
        managedObjectContext = [_managedObjectContext retain];

        engineDefaults = [[NSUserDefaults alloc] init];
        [engineDefaults addSuiteNamed:@"com.mothership.Library.Engine"];
        localEngineID = [engineDefaults valueForKey:@"machine-id"];
        if (!localEngineID) {
            [engineDefaults setValue:localEngineID = [NSString stringWithUUID] forKey:@"machine-id"];
            [engineDefaults synchronize];
        }
        
        browser = [[NSNetServiceBrowser alloc] init];
        [browser setDelegate:self];
        [browser searchForServicesOfType:@"_mezzanine._tcp." inDomain:@""]; 
        [self performSelector:@selector(startLocalEngine) withObject:nil afterDelay:1.0];
    }
    
    return self;
}

- (void) dealloc
{
    NSAssert(0 == [engineControllers count], @"closeAllEngines not called before dealloc");
    [browser release];
    [engineDefaults release];
    [localEngineID release];
    [engineControllers release];
    [managedObjectContext release];
    [super dealloc];
}

- (void) startLocalEngine
{
    NSLog(@"Starting local engine.");
    localEngine = [NSTask launchedTaskWithLaunchPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Engine"] arguments:[NSArray array]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(localEngineDidTerminate:) name:(NSString*)NSTaskDidTerminateNotification object:localEngine]; 
}

- (void) netService:(NSNetService*)netService didNotResolve:(NSDictionary*)errorDict
{
    NSLog(@"There was an error while attempting to resolve %@.", [netService name]);
}

- (void) netServiceDidResolveAddress:(NSNetService*)netService
{
    NSString* machineId = [netService name];
    NSDictionary* rawData = [NSNetService dictionaryFromTXTRecordData:[netService TXTRecordData]];
    NSString* machineName = [[[NSString alloc] initWithData:[rawData objectForKey:@"Machine Name"] encoding:NSUTF8StringEncoding] autorelease];
    if (machineName && machineId) {
         NSDictionary* options = [NSDictionary dictionaryWithObjectsAndKeys:
            machineId, @"Machine Id",
            machineName, @"Machine Name",
            nil
        ];

        EngineController* controller = [[EngineController alloc] initWithNetService:netService managedObjectContext:managedObjectContext options:options];
        [engineControllers setObject:controller forKey:machineId];
        NSLog(@"Added net service %@", machineId);
        if ([machineId isEqualToString:localEngineID]) {
            NSLog(@"Started net service %@", machineId);
            [controller connect];
        }
    }
}

- (void) netServiceBrowserDidStopSearch:(NSNetServiceBrowser*)netServiceBrowser
{
    NSLog(@"Stopped search.");
}

- (void) netServiceBrowser:(NSNetServiceBrowser*)netServiceBrowser didFindService:(NSNetService*)netService moreComing:(BOOL)moreComing
{
    [netService setDelegate:self];
    [netService resolveWithTimeout:5.0];
    [netService retain];
    
    NSString* machineId = [netService name];
    if ([machineId isEqualToString:localEngineID]) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(startLocalEngine) object:nil];
    } else if (!moreComing && ![engineControllers objectForKey:localEngineID] && !localEngine) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(startLocalEngine) object:nil];
        [self startLocalEngine];
    }
}

- (void)netServiceBrowser:(NSNetServiceBrowser*)netServiceBrowser didRemoveService:(NSNetService*)netService moreComing:(BOOL)moreComing 
{
    [netService stop];
    NSString* machineId = [netService name];
    EngineController* engineController = [engineControllers objectForKey:machineId];
    if (engineController) {
        [engineController disconnect];
        [engineControllers removeObjectForKey:machineId];
    }
}

- (void) localEngineDidTerminate:(NSNotification*)notification 
{
    NSAlert* a = [NSAlert alertWithMessageText:@"Local Engine Quit" 
                                 defaultButton:@"OK" 
                               alternateButton:nil 
                                   otherButton:nil
                     informativeTextWithFormat:@"The local engine quit.  The whole app should."];    
    [a runModal];
    
    //  The task is dead, no need for a listener.
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (EngineController*) engineByUUIDKey:(NSString*)UUIDKey
{
    return [engineControllers objectForKey:UUIDKey];
}

- (void) stop 
{
    [browser stop];
    [browser removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    for (NSString* key in engineControllers) {
        EngineController* engineController = [engineControllers objectForKey:key];
        [engineController disconnect];
    }
    [engineControllers removeAllObjects];
}

@end
