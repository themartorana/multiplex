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
    /**/
    IBOutlet DrawerView* drawerView;
    /**/
    IBOutlet NSView* infoPaneView;
    IBOutlet NSView* searchView;
    /**/
    IBOutlet InfoPaneFormController* infoPaneFormController;
    IBOutlet UserVoiceFeedbackPanel* userVoiceFeedbackPanel;
    /**/
    IBOutlet NSButton* userVoiceButton;
    /**/
    EngineController* engineController;
    NSManagedObjectModel* managedObjectModel;
    NSPersistentStoreCoordinator* persistentStoreCoordinator;
    NSManagedObjectContext* appManagedObjectContext;
    NSManagedObjectContext* engineManagedObjectContext;
}

@property (readonly) NSManagedObjectContext* appManagedObjectContext;

- (IBAction) showUserVoiceFeedbackSheet:(id)sender;
- (IBAction) toggleFullScreen:(id)sender;

@end
