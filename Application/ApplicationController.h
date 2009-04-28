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
@class MovieURL;
@class MAAttachedWindow;
@class DeleteConfirmationPanel;

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
    IBOutlet NSView* searchExplanationView;
    /**/
    MovieDetailController* movieDetailController;
    MovieLookupController* movieLookupController;
    IBOutlet UserVoiceFeedbackPanel* userVoiceFeedbackPanel;
    /**/
    IBOutlet NSButton* userVoiceButton;
    /**/
    IBOutlet NSImageView* windowResizeThumb;
    
    IBOutlet NSMenu* movieContextMenu;
    IBOutlet NSMenuItem* buyFromAmazonMenuItem;
    IBOutlet NSMenuItem* burnWithToastMenuItem;
    
    IBOutlet DeleteConfirmationPanel* deletePanel;
    
    /**/
    PreferencesWindowController* preferencesWindowController;    
    
    EngineController* engineController;
    NSManagedObjectModel* managedObjectModel;
    NSPersistentStoreCoordinator* persistentStoreCoordinator;
    NSManagedObjectContext* appManagedObjectContext;
    NSManagedObjectContext* engineManagedObjectContext;
    /**/
    Movie* selectedMovie;
    Movie* hoveredMovie;
    NSString* searchQuery;
    NSView* viewInFullScreen;
    IBOutlet NSButton* infoViewButton;
    
    id<DrawerViewControllerProtocol> currentDrawerViewController;
    
    int selectedSegment;
    
    NSPredicate* moviesFilterPredicate;
    
    /* Attached windows */
    MAAttachedWindow* tipWindow;
}

@property (retain) NSString* searchQuery;
@property (retain) Movie* selectedMovie;
@property (retain) Movie* hoveredMovie;
@property (retain) NSDictionary* parameters;
@property (retain) id<DrawerViewControllerProtocol> currentDrawerViewController;
@property (retain) NSPredicate* moviesFilterPredicate;

@property (readonly) NSManagedObjectContext* appManagedObjectContext;
@property (readonly) NSMenu* movieContextMenu;

@property int selectedSegment;

- (IBAction) checkForUpdates:(id)sender;
- (IBAction) showUserVoiceFeedbackSheet:(id)sender;
- (IBAction) toggleFullScreen:(id)sender;
- (IBAction) addNonDVDMovie:(id)sender;

- (IBAction) switchToStadiumLayoutManager:(id)sender;
- (IBAction) switchToGridLayoutManager:(id)sender;
- (IBAction) switchToLinearLayoutManager:(id)sender;

- (IBAction) showPreferencesWindow:(id)sender;

- (IBAction) showSampleData:(id)sender;

- (IBAction) playMovie:(id)sender;
- (IBAction) refreshInfoFromInternetByUPC:(id)sender;
- (IBAction) refreshInfoFromInternetByTitle:(id)sender;
- (IBAction) deleteMovie:(id)sender;
- (IBAction) buyFromAmazon:(id)sender;
- (IBAction) focusSearch:(id)sender;
- (IBAction) goToMultiplexSupport:(id)sender;

- (IBAction) burnWithToast:(id)sender;

- (IBAction) toggleHideUnavailableMovies:(id)sender;

- (IBAction) dontShowTooltipAgain:(id)sender;
- (IBAction) resetToolTipAlerts:(id)sender;

- (void) showMovieDetailAndSelectHomeTabForMovie:(Movie*)movie;
- (void) showMovieDetailAndSelectDiscsTabMovie:(Movie*)movie;
- (void) showMovieLookupForMovie:(Movie*)movie byTitle:(NSNumber*)byTitle;
- (void) closeDrawerView:(NSNotification*)notification;
- (void) setSelectedMovieFromNotificationIfNecessary:(NSNotification*)n;
- (void) approveMovieSelectionClick:(NSInvocation*)invocation forMovieLayer:(MovieLayer*)movieLayer;
- (void) deleteCurrentMovie;

- (void) showSearchTooltip;
- (void) removeToolTipWindow;

- (BOOL) isInFullScreen;
- (BOOL) isDrawerViewOpen;

- (MovieURL*) getAmazonURL:(Movie*)movie;

@end
