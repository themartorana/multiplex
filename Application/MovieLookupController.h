#import <Cocoa/Cocoa.h>
#import "DrawerViewControllerProtocol.h"
#import "ExecuteTokenProtocol.h"

@class Activity;
@class ApplicationController;
@class DiscIdentQuery;
@class WebView;
@class DrawerView;
@class Movie;
@class BoxArtImageView;
@class MovieDetailController;
@class MovieURL;

@interface MovieLookupController : NSObject <DrawerViewControllerProtocol> {
    ApplicationController* applicationController;
    DrawerView* drawerView;
    Movie* movie;
    NSManagedObjectContext* managedObjectContext;
    NSEntityDescription* boxArtEntity;
    NSEntityDescription* participantEntity;
    NSEntityDescription* movieURLEntity;
    
    IBOutlet NSView* searchByUPCorEANView;
    IBOutlet NSView* searchByTitleView;
    IBOutlet NSView* searchingView;
    IBOutlet NSView* searchResultsView;
    
    int amazonQueryType;
    NSArray* amazonQueryResults;
    NSNumber* resultIndex;
    
    IBOutlet NSTextField* searchResultsMovieTitle;
    IBOutlet BoxArtImageView* searchResultsBoxArt;
    IBOutlet NSSegmentedControl* backAndForwardButtons;
    
    IBOutlet NSBox* resultsBox;
    
    IBOutlet WebView* searchResultsDescriptionWebView; 
    
    NSString* gtinToSearch;
    NSString* titleToSearch;
    
    id<ExecuteTokenProtocol> relinquishExecuteToken;
}

@property (retain) Movie* movie;
@property (retain) NSArray* amazonQueryResults;
@property (retain) NSNumber* resultIndex;
@property (readonly) NSString* resultViewLineOneText;
@property (readonly) NSString* resultViewLineTwoText;

@property (retain) NSString* gtinToSearch;
@property (retain) NSString* titleToSearch;


- (id) initWithApplicationController:(ApplicationController*)_applicationController drawerView:(DrawerView*)_drawerView;

- (IBAction) skipToUPCEntry:(id)sender;
- (IBAction) skipToTitleEntry:(id)sender;
- (IBAction) skipToManualEntry:(id)sender;

- (IBAction) lookUpByUPCorEAN:(id)sender;
- (IBAction) lookUpByTitle:(id)sender;
- (IBAction) selectResult:(id)sender;
- (IBAction) showNextResult:(id)sender;
- (IBAction) showPreviousResult:(id)sender;
- (IBAction) backToSearch:(id)sender;

@end
