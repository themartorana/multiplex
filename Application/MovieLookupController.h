#import <Cocoa/Cocoa.h>

@class Activity;
@class AmazonQuery;
@class ApplicationController;
@class DiscIdentQuery;
@class ImageQuery;
@class WebView;
@class DrawerView;
@class Movie;
@class CoverArtImageView;
@class MovieDetailController;

@interface MovieLookupController : NSObject {
    Movie* movie;
    
    IBOutlet ApplicationController* applicationController;
    IBOutlet NSArrayController* movies;
    IBOutlet DrawerView* drawerView;
    
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
    IBOutlet CoverArtImageView* searchResultsBoxArt;
    IBOutlet NSSegmentedControl* backAndForwardButtons;
    
    IBOutlet WebView* searchResultsDescriptionWebView; 
    
    AmazonQuery* amazonQuery;
    ImageQuery* imageQuery;
}

@property (retain) Movie* movie;

- (void) startWithMovie:(Movie*)movie;

- (IBAction) skipEnterUPC:(id)sender;

- (IBAction) lookUpUPC:(id)sender;
- (IBAction) lookUpTitle:(id)sender;
- (IBAction) selectResult:(id)sender;
- (IBAction) showNextResult:(id)sender;
- (IBAction) showPreviousResult:(id)sender;
- (IBAction) backToSearch:(id)sender;

@end
