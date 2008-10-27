#import <Cocoa/Cocoa.h>

@class MainView;
@class DrawerView;
@class EngineController;
@class InfoPaneFormController;
@class UserVoiceFeedbackPanel;

@interface WindowController : NSWindowController {
    NSDictionary* parameters;
    IBOutlet NSTextField* licensingAndVersionInfo;
    /**/
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
    IBOutlet NSButton* userVoiceButton;
    /**/
    EngineController* engineController;
    NSManagedObjectModel* managedObjectModel;
    NSPersistentStoreCoordinator* persistentStoreCoordinator;
    NSManagedObjectContext* appManagedObjectContext;
    NSManagedObjectContext* engineManagedObjectContext;
}

@property (readonly) NSManagedObjectContext* appManagedObjectContext;
@property (retain) NSDictionary* parameters;

- (IBAction) checkForUpdates:(id)sender;
- (IBAction) showUserVoiceFeedbackSheet:(id)sender;
- (IBAction) toggleFullScreen:(id)sender;

- (IBAction) switchToStadiumLayoutManager:(id)sender;
- (IBAction) switchToGridLayoutManager:(id)sender;
- (IBAction) switchToLinearLayoutManager:(id)sender;

@end
