#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@class Movie;
@class DrawerView;
@class InfoPaneDiscsView;
@class CoverArtImageView;
@class LayerBackedButtonView;
@class TextView;

@interface MovieDetailController : NSObject {
    Movie* movie;
    
    NSColor* labelColor;

    IBOutlet DrawerView* drawerView;
    IBOutlet NSView* infoPaneView;

    IBOutlet WebView* descriptionWebView;
    IBOutlet InfoPaneDiscsView* infoPaneDiscsView;
    IBOutlet CoverArtImageView* coverArtImageView;
    
    IBOutlet NSTabView* infoTabView;
    IBOutlet NSTabViewItem* discsTabViewItem;
    
    IBOutlet TextView* discTitleView;
    
    IBOutlet LayerBackedButtonView* playButtonView;
    
    BOOL valuesAreEditable;
}

@property (retain) Movie* movie;
@property (readonly) NSColor* labelColor;
@property BOOL valuesAreEditable;

- (IBAction) startWithMovie:(Movie*)movie;

- (void) showHomeTab;
- (void) showDiscsTab;

@end
