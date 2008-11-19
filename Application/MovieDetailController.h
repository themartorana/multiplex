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
    /**/
    Movie* movie;
    NSColor* labelColor;
    BOOL valuesAreEditable;
    
    BOOL isAvailableFromAmazon;
}

- (id) initWithApplicationController:(ApplicationController*)_applicationController drawerView:(DrawerView*)_drawerView;

@property (retain) Movie* movie;
@property (readonly) NSColor* labelColor;
@property BOOL valuesAreEditable;
@property BOOL isAvailableFromAmazon;

/* Fake properties */
@property (readonly) NSPredicate* actorsFilter;
@property (readonly) NSPredicate* crewFilter;
@property (readonly) NSSortDescriptor* discsSortDescriptor;


- (IBAction) startWithMovie:(Movie*)movie;
- (IBAction) selectTab:(id)sender;

- (IBAction) refreshMovieInfoFromInternetByUPC:(id)sender;
- (IBAction) refreshMovieInfoFromInternetByTitle:(id)sender;
- (IBAction) deleteCoverArtForMovie:(id)sender;
- (IBAction) deleteMetadataForMovie:(id)sender;
- (IBAction) buyFromAmazon:(id)sender;

- (IBAction) playSelectedMovie:(id)sender;
- (IBAction) playDisc:(id)obj;

- (void) showHomeTab;
- (void) showDiscsTab;

@end
