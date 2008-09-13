#import "EngineClientController.h"
#import "EngineClient.h"
#import "MessageProtocol.h"
#import "NSString+UUID.h"

@interface EngineClientController (Private)

- (void) netService:(NSNetService*)netService didNotResolve:(NSDictionary*)errorDict;
- (void) netService:(NSNetService*)netService dfidUpdateTXTRecordData:(NSData*)data;
- (void) netServiceDidResolveAddress:(NSNetService*)netService;

@end


@implementation EngineClientController
@synthesize localEngineID;

- (id) initWithManagedObjectContext:(NSManagedObjectContext*)_managedObjectContext 
{
    if (self = [super init]) {
        engineControllers = [[NSMutableDictionary alloc] init];
        managedObjectContext = [_managedObjectContext retain];

        engineDefaults = [[NSUserDefaults alloc] init];
        [engineDefaults addSuiteNamed:@"com.multiplexapp.Engine"];
        localEngineID = [engineDefaults valueForKey:@"machine-id"];
        if (!localEngineID) {
            [engineDefaults setValue:localEngineID = [NSString stringWithUUID] forKey:@"machine-id"];
            [engineDefaults synchronize];
        }
        
        browser = [[NSNetServiceBrowser alloc] init];
        [browser setDelegate:self];
        [browser searchForServicesOfType:@"_com_multiplexapp_Engine._tcp." inDomain:@""]; 
        
        NSString* pathToEngine = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Engine"];
        NSTask* launchctl = [NSTask launchedTaskWithLaunchPath:@"/bin/launchctl" arguments:[NSArray arrayWithObjects:@"submit", @"-l", @"com.multiplexapp.Engine", pathToEngine, nil]];
        [launchctl waitUntilExit];
        if (0 == [launchctl terminationStatus]) {
            NSLog(@"Started local engine.");
        } else {
            NSLog(@"Local engine may already be running.");
        }
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

        EngineClient* controller = [[EngineClient alloc] initWithNetService:netService managedObjectContext:managedObjectContext options:options];
        [engineControllers setObject:controller forKey:machineId];
        NSLog(@"Added net service %@", machineId);
//        if ([machineId isEqualToString:localEngineID]) {
            NSLog(@"Started net service %@", machineId);
            [controller connect];
//        }
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
}

- (void)netServiceBrowser:(NSNetServiceBrowser*)netServiceBrowser didRemoveService:(NSNetService*)netService moreComing:(BOOL)moreComing 
{
    [netService stop];
    NSString* machineId = [netService name];
    EngineClient* engineController = [engineControllers objectForKey:machineId];
    if (engineController) {
        [engineController disconnect];
        [engineControllers removeObjectForKey:machineId];
    }
}

- (EngineClient*) engineByUUIDKey:(NSString*)UUIDKey
{
    return [engineControllers objectForKey:UUIDKey];
}

- (void) stop 
{
    [browser stop];
    [browser removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    for (NSString* key in engineControllers) {
        EngineClient* engineController = [engineControllers objectForKey:key];
        [engineController disconnect];
    }
    [engineControllers removeAllObjects];

    NSTask* launchctl = [NSTask launchedTaskWithLaunchPath:@"/bin/launchctl" arguments:[NSArray arrayWithObjects:@"remove", @"com.multiplexapp.Engine", nil]];
    [launchctl waitUntilExit];
    if (0 == [launchctl terminationStatus]) {
        NSLog(@"Stoppped local engine.");
    } else {
        NSLog(@"Local engine may still be running.");
    }
}

@end
