#import <Cocoa/Cocoa.h>

@class MainView;
@class DrawerView;
@class EngineController;
@class InfoPaneFormController;
@class UserVoiceFeedbackPanel;

@interface WindowController : NSWindowController {
    IBOutlet NSArrayController* movies;
    /**/
    IBOutlet MainView* mainView;
    IBOutlet DrawerView* drawerView;
    /**/
    IBOutlet NSView* infoPaneView;
    IBOutlet NSView* searchView;
    /**/
    IBOutlet InfoPaneFormController* infoPaneFormController;
    IBOutlet UserVoiceFeedbackPanel* userVoiceFeedbackPanel;
    /**/
    EngineController* engineController;
    NSManagedObjectModel* managedObjectModel;
    NSPersistentStoreCoordinator* persistentStoreCoordinator;
    NSManagedObjectContext* managedObjectContext;
}

@property (readonly) NSManagedObjectContext* managedObjectContext;

- (IBAction) showUserVoiceFeedbackSheet:(id)sender;

@end
