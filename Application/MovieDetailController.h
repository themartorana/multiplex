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
    IBOutlet NSView* infoPaneView;
    IBOutlet WebView* descriptionWebView;
    IBOutlet MovieDetailDiscsView* discsView;
    IBOutlet BoxArtImageView* coverArtImageView;
    IBOutlet NSTabView* infoTabView;
    IBOutlet NSTabViewItem* discsTabViewItem;
    IBOutlet LayerBackedButtonView* playButtonView;
    /**/
    Movie* movie;
    NSColor* labelColor;
    BOOL valuesAreEditable;
}

- (id) initWithApplicationController:(ApplicationController*)_applicationController drawerView:(DrawerView*)_drawerView;

@property (retain) Movie* movie;
@property (readonly) NSColor* labelColor;
@property BOOL valuesAreEditable;

- (IBAction) startWithMovie:(Movie*)movie;
- (IBAction) refreshMovieInfoFromInternet:(id)sender;

- (void) showHomeTab;
- (void) showDiscsTab;

@end
