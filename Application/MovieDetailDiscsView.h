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

    NSArray* contextMenuItemsForRightClickOnDiscs;
    
    Movie* movie;
    BOOL isReady;
    
    DiscDropView* dropView;
    
    NSString* currentCoreDataObjectID;
}

@property (retain) Movie* movie;
@property BOOL isReady;

@end
