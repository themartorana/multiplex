#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

#import "DrawerViewControllerProtocol.h"

@class Movie;
@class ApplicationController;
@class DrawerView;
@class MovieDetailDiscsView;
@class BoxArtImageView;
@class LayerBackedButtonView;

@interface MovieDetailController : NSObject <DrawerViewControllerProtocol> {
    ApplicationController* applicationController;
    DrawerView* drawerView;
    /**/
    IBOutlet NSBox* backgroundBox;
    IBOutlet NSBox* editImageBox;
    IBOutlet NSView* infoPaneView;
    
    IBOutlet WebView* overviewWebView;
    IBOutlet WebView* descriptionWebView;
    
    IBOutlet MovieDetailDiscsView* discsView;
    
    IBOutlet BoxArtImageView* coverArtImageView;
    IBOutlet BoxArtImageView* coverArtImageEditView;
    
    IBOutlet NSSegmentedControl* tabSelector;
    IBOutlet NSTabView* infoTabView;
    IBOutlet NSTabViewItem* overviewTabViewItem;
    IBOutlet NSTabViewItem* discsTabViewItem;
    IBOutlet LayerBackedButtonView* playButtonView;
    
    IBOutlet NSArrayController* actorsArrayController;
    IBOutlet NSArrayController* crewArrayController;
    
    IBOutlet NSTableView* actorsTableView;
    IBOutlet NSTableView* crewTableView;
    /**/
    Movie* movie;
    NSColor* labelColor;
    BOOL valuesAreEditable;
    
    BOOL isAvailableFromAmazon;
    BOOL isBurnPossible;
}

- (id) initWithApplicationController:(ApplicationController*)_applicationController drawerView:(DrawerView*)_drawerView;

@property (retain) Movie* movie;
@property (readonly) NSColor* labelColor;
@property BOOL valuesAreEditable;
@property BOOL isAvailableFromAmazon;
@property BOOL isBurnPossible;

/* Fake properties */
@property (readonly) NSPredicate* actorsFilter;
@property (readonly) NSPredicate* crewFilter;
@property (readonly) NSSortDescriptor* discsSortDescriptor;

- (IBAction) selectTab:(id)sender;

- (IBAction) refreshMovieInfoFromInternetByUPC:(id)sender;
- (IBAction) refreshMovieInfoFromInternetByTitle:(id)sender;
- (IBAction) deleteMovie:(id)sender;
- (IBAction) buyFromAmazon:(id)sender;

- (IBAction) burnWithToast:(id)sender;

- (IBAction) playSelectedMovie:(id)sender;
- (IBAction) playDisc:(id)obj;

- (IBAction) addActor:(id)sender;
- (IBAction) addCrewMember:(id)sender;

- (NSString*) generateDescriptionHtmlString;

- (void) showHomeTab;
- (void) showDiscsTab;

@end
