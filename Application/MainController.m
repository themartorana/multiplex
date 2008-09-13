#import "MainController.h"
#import "EngineController.h" 

@implementation MainController
@synthesize managedObjectContext;

- (id) init 
{
    if (self == [super init]) {
        managedObjectModel = [[NSManagedObjectModel mergedModelFromBundles:nil] retain];

        persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:managedObjectModel];
        [persistentStoreCoordinator addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:nil options:nil error:nil];

        managedObjectContext = [[NSManagedObjectContext alloc] init];
        [managedObjectContext setPersistentStoreCoordinator:persistentStoreCoordinator];
       
        engineController = [[EngineController alloc] initWithManagedObjectContext:managedObjectContext];
    }
    return self;
}

- (void) dealloc 
{
    [managedObjectModel release];
    [persistentStoreCoordinator release];
    [managedObjectContext release];
    [engineController release];
    [super dealloc];
}

- (void) applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self.window makeKeyAndOrderFront:nil];
}

- (void) applicationWillTerminate:(NSNotification *)aNotification
{
    [engineController stop];
}


///
/// Launch the selected movie
/// 
- (IBAction) launchMovie:(id)sender 
{
    NSManagedObject* disc = [[discsController selectedObjects] objectAtIndex:0];
    if (disc) {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[disc valueForKey:@"url"]]];
    }
}

@end