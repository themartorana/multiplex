#import <Cocoa/Cocoa.h>

@class Activity;
@class AmazonQuery;
@class DiscIdentQuery;
@class ImageQuery;
@class WebView;
@class DrawerView;
@class Movie;
@class CoverArtImageView;
@class InfoPaneFormController;

static NSString* const kAmazonAccessKey = @"01Y2NSCMDJ3VJXTCBTR2";

@interface DrawerController : NSObject {
    Movie* selectedMovie;
    
    IBOutlet NSArrayController* movies;
    IBOutlet DrawerView* drawerView;
    
    IBOutlet NSView* movieInfoView;
    IBOutlet NSView* noMovieSelectedView;
    
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
    
    Movie* movie;
    
    IBOutlet NSTextField* upcTextField;
    IBOutlet NSTextField* titleTextField;
    IBOutlet NSTextField* searchResultsRecordCount;
    IBOutlet NSTextField* searchResultsMovieTitle;
    IBOutlet CoverArtImageView* searchResultsBoxArt;
    IBOutlet NSSegmentedControl* backAndForwardButtons;
    
    IBOutlet WebView* searchResultsDescriptionWebView; 
    
    IBOutlet InfoPaneFormController* formController;
    
    AmazonQuery* amazonQuery;
    ImageQuery* imageQuery;
}

- (IBAction) skipEnterUPC:(id)sender;

- (IBAction) lookUpUPC:(id)sender;
- (IBAction) lookUpTitle:(id)sender;
- (IBAction) selectResult:(id)sender;
- (IBAction) showNextResult:(id)sender;
- (IBAction) showPreviousResult:(id)sender;
- (IBAction) backToSearch:(id)sender;

@end
