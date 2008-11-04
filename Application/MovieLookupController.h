#import <Cocoa/Cocoa.h>

@class Activity;
@class AmazonQuery;
@class ApplicationController;
@class DiscIdentQuery;
@class ImageQuery;
@class WebView;
@class DrawerView;
@class Movie;
@class BoxArtImageView;
@class MovieDetailController;

@interface MovieLookupController : NSObject {
    ApplicationController* applicationController;
    DrawerView* drawerView;
    Movie* movie;
    NSManagedObjectContext* managedObjectContext;
    NSEntityDescription* boxArtEntity;
    
    ///////////////////////////////////
    /// 
    /// LOOKUP STUFF
    /// 
    ///////////////////////////////////
    
    IBOutlet NSView* searchForMovieView;
    IBOutlet NSView* searchingView;
    IBOutlet NSView* searchResultsView;
    
    NSArray* amazonQueryResults;
    int resultIndex;
    
    IBOutlet NSTextField* upcTextField;
    IBOutlet NSTextField* titleTextField;
    IBOutlet NSTextField* searchResultsRecordCount;
    IBOutlet NSTextField* searchResultsMovieTitle;
    IBOutlet BoxArtImageView* searchResultsBoxArt;
    IBOutlet NSSegmentedControl* backAndForwardButtons;
    
    IBOutlet WebView* searchResultsDescriptionWebView; 
    
    AmazonQuery* amazonQuery;
    ImageQuery* imageQuery;
}

@property (retain) Movie* movie;

- (id) initWithApplicationController:(ApplicationController*)_applicationController drawerView:(DrawerView*)_drawerView;

- (void) startWithMovie:(Movie*)movie;

- (IBAction) cancel:(id)sender;

- (IBAction) lookUpUPC:(id)sender;
- (IBAction) lookUpTitle:(id)sender;
- (IBAction) selectResult:(id)sender;
- (IBAction) showNextResult:(id)sender;
- (IBAction) showPreviousResult:(id)sender;
- (IBAction) backToSearch:(id)sender;

@end
