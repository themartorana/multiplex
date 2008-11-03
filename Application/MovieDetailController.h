#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@class Movie;
@class ApplicationController;
@class DrawerView;
@class MovieDetailDiscsView;
@class CoverArtImageView;
@class LayerBackedButtonView;
@class TextView;

@interface MovieDetailController : NSObject {
    ApplicationController* applicationController;
    DrawerView* drawerView;
    /**/
    IBOutlet NSView* infoPaneView;
    IBOutlet WebView* descriptionWebView;
    IBOutlet MovieDetailDiscsView* discsView;
    IBOutlet CoverArtImageView* coverArtImageView;
    IBOutlet NSTabView* infoTabView;
    IBOutlet NSTabViewItem* discsTabViewItem;
    IBOutlet TextView* discTitleView;
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

- (void) showHomeTab;
- (void) showDiscsTab;

@end
