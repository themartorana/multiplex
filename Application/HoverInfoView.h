#import <Cocoa/Cocoa.h>

@class Movie;
@class WebView;

@interface HoverInfoView : NSView {
    Movie* movie;
    IBOutlet WebView* webView;
    BOOL inFlipPosition;
}

@property (retain) Movie* movie;
@property BOOL inFlipPosition;

@end
