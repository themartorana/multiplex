#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@class Movie;
@class InfoPaneDiscsView;
@class CoverArtImageView;
@class LayerBackedButtonView;

@interface InfoPaneFormController : NSObject {
    Movie* movie;
    
    NSColor* labelColor;
    
    IBOutlet WebView* descriptionWebView;
    IBOutlet InfoPaneDiscsView* infoPaneDiscsView;
    IBOutlet CoverArtImageView* coverArtImageView;
    
    IBOutlet NSTabView* infoTabView;
    IBOutlet NSTabViewItem* discsTabViewItem;
    
    IBOutlet LayerBackedButtonView* playButtonView;
    
    BOOL valuesAreEditable;
}

@property (retain) Movie* movie;
@property (readonly) NSColor* labelColor;
@property BOOL valuesAreEditable;

- (void) showHomeTab;
- (void) showDiscsTab;

@end
