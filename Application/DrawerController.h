#import <Cocoa/Cocoa.h>

@class DrawerView;
@class Movie;

@interface DrawerController : NSObject {
    Movie* selectedMovie;
    
    IBOutlet NSArrayController* movies;
    IBOutlet DrawerView* drawerView;
    
    IBOutlet NSView* movieInfoView;
    IBOutlet NSView* noMovieSelectedView;
    IBOutlet NSView* enterUPCView;
}

@end
