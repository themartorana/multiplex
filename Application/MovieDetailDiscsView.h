#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@class Movie;
@class MovieDetailController;

@interface MovieDetailDiscsView : NSView {
    IBOutlet WebView* webView;
    IBOutlet MovieDetailController* movieDetailController;
    
    Movie* movie;
    BOOL isReady;
}

@property (retain) Movie* movie;
@property BOOL isReady;

@end
