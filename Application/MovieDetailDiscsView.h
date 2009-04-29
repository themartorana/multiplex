#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@class Movie;
@class MovieDetailController;
@class DiscDropView;
@class DiscRenameAndMakeIndependentMovie;

@interface MovieDetailDiscsView : NSView {
    IBOutlet WebView* webView;
    IBOutlet MovieDetailController* movieDetailController;
    IBOutlet DiscRenameAndMakeIndependentMovie* renamePanel;
    IBOutlet NSTextField* renameOrBreakOutField;
    
    Movie* movie;
    BOOL isReady;
    
    DiscDropView* dropView;
    
    NSString* currentCoreDataObjectID;
    
    NSMenuItem* renameMenuItem;
    NSMenuItem* removeMenuItem;
    NSMenuItem* sepMenuItem;
    NSMenuItem* revealInFinderItem;
    NSMenuItem* deleteFromMultiplexItem;
}

@property (retain) Movie* movie;
@property BOOL isReady;

@end
