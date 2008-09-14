#import "MainController.h"
#import "EngineController.h" 
#import "Media.h" 

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

- (void) applicationDidFinishLaunching:(NSNotification*)notification
{
    [self.window makeKeyAndOrderFront:nil];
}

- (void) applicationWillTerminate:(NSNotification*)notification
{
    [engineController shutdown];
}


///
/// Launch the selected movie
/// 
- (IBAction) launchMovie:(id)sender 
{
    Media* media = [[mediaController selectedObjects] objectAtIndex:0];
    if (media) {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:media.url]];
    }
}

@end