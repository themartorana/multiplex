#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@class Movie;
@class InfoPaneDiscsView;
@class CoverArtImageView;

@interface InfoPaneFormController : NSObject {
    Movie* movie;
    
    NSColor* labelColor;
    
    IBOutlet WebView* descriptionWebView;
    IBOutlet InfoPaneDiscsView* infoPaneDiscsView;
    IBOutlet CoverArtImageView* coverArtImageView;
    
    IBOutlet NSTabView* infoTabView;
    IBOutlet NSTabViewItem* discsTabViewItem;
}

@property (retain) Movie* movie;
@property (readonly) NSColor* labelColor;

- (void) showHomeTab;
- (void) showDiscsTab;

@end
