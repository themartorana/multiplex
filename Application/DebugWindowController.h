#import <Cocoa/Cocoa.h>
#import "EngineController.h"

@interface DebugWindowController : NSWindowController {
    EngineController* engineController;
    NSManagedObjectModel* managedObjectModel;
    NSPersistentStoreCoordinator* persistentStoreCoordinator;
    NSManagedObjectContext* managedObjectContext;
    /**/
    IBOutlet NSArrayController *mediaController;
}

@property (readonly) NSManagedObjectContext* managedObjectContext;

- (IBAction) launchMovie:(id)sender;

@end
