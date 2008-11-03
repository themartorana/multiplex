#import <Cocoa/Cocoa.h>

@class Activity;
@class AmazonQuery;
@class DiscIdentQuery;
@class ImageQuery;
@class WebView;
@class DrawerView;
@class Movie;
@class CoverArtImageView;
@class InfoPaneFormController;
@class InfoLookupController;

@interface DrawerController : NSObject {
    Movie* selectedMovie;
    
    IBOutlet NSArrayController* movies;
    IBOutlet DrawerView* drawerView;
    
    IBOutlet NSView* infoPaneView;
    IBOutlet NSView* noMovieSelectedView;
    IBOutlet NSView* searchForMovieView;
    
    IBOutlet InfoPaneFormController* formController;
    IBOutlet InfoLookupController* infoLookupController;
}

- (void) showInfoPanelAndSelectHomeTab:(id)sender;

@end
