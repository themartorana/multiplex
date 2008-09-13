#import <Cocoa/Cocoa.h>
#import "EngineController.h"

@interface MainController : NSWindowController {
    EngineController* engineController;
    NSManagedObjectModel* managedObjectModel;
    NSPersistentStoreCoordinator* persistentStoreCoordinator;
    NSManagedObjectContext* managedObjectContext;
    /**/
    IBOutlet NSArrayController *discsController;
    IBOutlet NSButton* saveBtn;
}

@property (readonly) NSManagedObjectContext* managedObjectContext;

- (IBAction) launchMovie:(id)sender;

@end
