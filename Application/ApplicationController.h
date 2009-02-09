#import <Cocoa/Cocoa.h>
#import "DrawerViewControllerProtocol.h"

@class MainView;
@class DrawerView;
@class EngineController;
@class MovieDetailController;
@class MovieLookupController;
@class UserVoiceFeedbackPanel;
@class Movie;
@class MovieLayer;
@class MainWindowContentView;
@class PreferencesWindowController;

@interface ApplicationController : NSWindowController {
    NSDictionary* parameters;
    IBOutlet NSTextField* licensingAndVersionInfo;
    /**/
    IBOutlet NSArrayController* movies;
    /**/
    IBOutlet MainWindowContentView* mainWindowContentView;
    IBOutlet MainView* mainView;
    IBOutlet DrawerView* drawerView;
    IBOutlet NSSearchField* searchField;
    /**/
    IBOutlet NSView* startUpSpinnerView;
    IBOutlet NSView* noDiscsView;
    IBOutlet NSView* noMovieSelectedView;
    IBOutlet NSView* searchForMovieView;
    /**/
    MovieDetailController* movieDetailController;
    MovieLookupController* movieLookupController;
    IBOutlet UserVoiceFeedbackPanel* userVoiceFeedbackPanel;
    /**/
    IBOutlet NSButton* userVoiceButton;
    /**/
    IBOutlet NSImageView* windowResizeThumb;
    
    /**/
    PreferencesWindowController* preferencesWindowController;    
    
    EngineController* engineController;
    NSManagedObjectModel* managedObjectModel;
    NSPersistentStoreCoordinator* persistentStoreCoordinator;
    NSManagedObjectContext* appManagedObjectContext;
    NSManagedObjectContext* engineManagedObjectContext;
    /**/
    Movie* selectedMovie;
    NSString* searchQuery;
    NSView* viewInFullScreen;
    IBOutlet NSButton* infoViewButton;
    
    id<DrawerViewControllerProtocol> currentDrawerViewController;
    
    int selectedSegment;
}

@property (retain) NSString* searchQuery;
@property (retain) Movie* selectedMovie;
@property (readonly) NSManagedObjectContext* appManagedObjectContext;
@property (retain) NSDictionary* parameters;
@property (retain) id<DrawerViewControllerProtocol> currentDrawerViewController;
@property int selectedSegment;

- (IBAction) checkForUpdates:(id)sender;
- (IBAction) showUserVoiceFeedbackSheet:(id)sender;
- (IBAction) toggleFullScreen:(id)sender;

- (IBAction) switchToStadiumLayoutManager:(id)sender;
- (IBAction) switchToGridLayoutManager:(id)sender;
- (IBAction) switchToLinearLayoutManager:(id)sender;

- (IBAction) showPreferencesWindow:(id)sender;

- (void) showMovieDetailAndSelectHomeTabForMovie:(Movie*)movie;
- (void) showMovieDetailAndSelectDiscsTabMovie:(Movie*)movie;
- (void) showMovieLookupForMovie:(Movie*)movie byTitle:(BOOL)byTitle;
- (void) closeDrawerView:(NSNotification*)notification;

- (void) setSelectedMovieFromNotificationIfNecessary:(NSNotification*)n;

- (void) approveMovieSelectionClick:(NSInvocation*)invocation forMovieLayer:(MovieLayer*)movieLayer;

- (BOOL) isInFullScreen;
- (BOOL) isDrawerViewOpen;
//- (BOOL) canSwitchDrawerControllers;

@end
