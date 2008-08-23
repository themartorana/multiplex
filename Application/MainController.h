#import <Cocoa/Cocoa.h>
#import "EnginesManager.h"

@interface MainController : NSWindowController {
    EnginesManager* enginesManager;
    NSManagedObjectModel* managedObjectModel;
    NSPersistentStoreCoordinator* persistentStoreCoordinator;
    NSManagedObjectContext* managedObjectContext;
    /**/
    IBOutlet NSArrayController *discsController;
}

@property (readonly) NSManagedObjectContext* managedObjectContext;

- (IBAction) launchMovie:(id)sender;

@end
