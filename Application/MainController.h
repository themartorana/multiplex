#import <Cocoa/Cocoa.h>
#import "EngineClientController.h"

@interface MainController : NSWindowController {
    EngineClientController* enginesManager;
    NSManagedObjectModel* managedObjectModel;
    NSPersistentStoreCoordinator* persistentStoreCoordinator;
    NSManagedObjectContext* managedObjectContext;
    
    NSMutableSet *dirtyObjects;
    
    /**/
    IBOutlet NSArrayController *discsController;
    IBOutlet NSButton* saveBtn;
}

@property (readonly) NSManagedObjectContext* managedObjectContext;

- (IBAction) launchMovie:(id)sender;
- (IBAction) saveChanges:(NSButton*)sender;

@end
