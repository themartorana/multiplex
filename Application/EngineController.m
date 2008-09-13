#import "EngineController.h"
#import "EngineConnection.h"
#import "MessageProtocol.h"
#import "NSString+UUID.h"

@interface EngineController (Private)

- (void) netService:(NSNetService*)netService didNotResolve:(NSDictionary*)errorDict;
- (void) netService:(NSNetService*)netService dfidUpdateTXTRecordData:(NSData*)data;
- (void) netServiceDidResolveAddress:(NSNetService*)netService;

@end

@implementation EngineController

- (id) initWithManagedObjectContext:(NSManagedObjectContext*)_managedObjectContext 
{
    if (self = [super init]) {
        engineControllers = [[NSMutableDictionary alloc] init];
        managedObjectContext = [_managedObjectContext retain];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_coreDataChangeNotification:) name:NSManagedObjectContextObjectsDidChangeNotification object:managedObjectContext];

        engineDefaults = [[NSUserDefaults alloc] init];
        [engineDefaults addSuiteNamed:@"com.multiplexapp.Engine"];
        localMachineID = [engineDefaults valueForKey:@"machine-id"];
        if (!localMachineID) {
            [engineDefaults setValue:localMachineID = [NSString stringWithUUID] forKey:@"machine-id"];
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
    [localMachineID release];
    [engineControllers release];
    [managedObjectContext release];
    [super dealloc];
}

- (void) stop 
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [browser stop];
    [browser removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    for (NSString* key in engineControllers) {
        EngineConnection* engineController = [engineControllers objectForKey:key];
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

        EngineConnection* controller = [[EngineConnection alloc] initWithNetService:netService managedObjectContext:managedObjectContext options:options];
        [engineControllers setObject:controller forKey:machineId];
        NSLog(@"Added net service %@", machineId);
//        if ([machineId isEqualToString:localEngineID]) {
            NSLog(@"Started net service %@", machineId);
            [controller connect];
//        }
    }
}

- (void) netServiceBrowser:(NSNetServiceBrowser*)netServiceBrowser didFindService:(NSNetService*)netService moreComing:(BOOL)moreComing
{
    [netService setDelegate:self];
    [netService resolveWithTimeout:5.0];
    [netService retain];
}

- (void) netServiceBrowser:(NSNetServiceBrowser*)netServiceBrowser didRemoveService:(NSNetService*)netService moreComing:(BOOL)moreComing 
{
    [netService stop];
    NSString* machineId = [netService name];
    EngineConnection* engineController = [engineControllers objectForKey:machineId];
    if (engineController) {
        [engineController disconnect];
        [engineControllers removeObjectForKey:machineId];
    }
}


#pragma mark -

- (void) _coreDataChangeNotification:(NSNotification*)notification
{
    for (NSManagedObject* managedObject in [[notification userInfo] objectForKey:NSUpdatedObjectsKey]) {
        NSString* entityName = [[managedObject entity] name];
        NSLog(@"%@", managedObject);
        if ([@"Disc" isEqualToString:entityName]) {
        } else if ([@"Movie" isEqualToString:entityName]) {
            NSArray* keys = [[managedObject changedValues] allKeys];
            if ([keys count] == 1 && [[keys objectAtIndex:0] isEqualToString:@"movieDiscs"]) {
                continue;
            }
        }
    }
}

@end
