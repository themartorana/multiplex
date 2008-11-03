#import <Cocoa/Cocoa.h>

@class MainView;
@class DrawerView;
@class EngineController;
@class InfoPaneFormController;
@class InfoLookupController;
@class UserVoiceFeedbackPanel;
@class Movie;

@interface ApplicationController : NSWindowController {
    NSDictionary* parameters;
    IBOutlet NSTextField* licensingAndVersionInfo;
    /**/
    IBOutlet NSArrayController* movies;
    /**/
    IBOutlet MainView* mainView;
    IBOutlet DrawerView* drawerView;
    IBOutlet NSSearchField* searchField;
    /**/
    IBOutlet NSView* infoPaneView;
    IBOutlet NSView* noDiscsView;
    IBOutlet NSView* noMovieSelectedView;
    IBOutlet NSView* searchForMovieView;
    /**/
    IBOutlet InfoPaneFormController* infoPaneFormController;
    IBOutlet InfoLookupController* infoLookupController;
    IBOutlet UserVoiceFeedbackPanel* userVoiceFeedbackPanel;
    /**/
    IBOutlet NSButton* userVoiceButton;
    /**/
    IBOutlet NSImageView* windowResizeThumb;
    EngineController* engineController;
    NSManagedObjectModel* managedObjectModel;
    NSPersistentStoreCoordinator* persistentStoreCoordinator;
    NSManagedObjectContext* appManagedObjectContext;
    NSManagedObjectContext* engineManagedObjectContext;
    /**/
    Movie* selectedMovie;
}

@property (retain) Movie* selectedMovie;
@property (readonly) NSManagedObjectContext* appManagedObjectContext;
@property (retain) NSDictionary* parameters;

- (IBAction) checkForUpdates:(id)sender;
- (IBAction) showUserVoiceFeedbackSheet:(id)sender;
- (IBAction) toggleFullScreen:(id)sender;

- (IBAction) switchToStadiumLayoutManager:(id)sender;
- (IBAction) switchToGridLayoutManager:(id)sender;
- (IBAction) switchToLinearLayoutManager:(id)sender;

- (IBAction) showInfoPanelAndSelectHomeTab:(id)sender;

@end
