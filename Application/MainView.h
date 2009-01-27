#import <Cocoa/Cocoa.h>
#import "Movie.h"
#import "MovieLayer.h"
#import "MultiplexLayoutManagerProtocol.h"

@class DrawerView;
@class ApplicationController;
@class HoverInfoView;

extern NSString* const kMultiplexDrawerIsOpenLayoutManagerClass;
extern NSString* const kMultiplexDrawerIsClosedLayoutManagerClass;

@interface MainView : NSView {
    IBOutlet ApplicationController* applicationController;
    IBOutlet DrawerView* drawerView;
    IBOutlet HoverInfoView* hoverInfoView;
    
    NSMutableDictionary* layersByID;
    NSArray* listOfMoviesInOrder;
    
    CALayer* floorLayer; // NR

    NSTrackingArea* mouseTrackingArea;
    
    id content;
    
    Movie* hoveredMovie;
    NSTimer* hoverTimer;
    
    MovieLayer* selectedMovieLayer;
    
    BOOL needsLayout;
    
    Class <MultiplexLayoutManagerProtocol> floorLayerLayoutManagerClass;
    id<MultiplexLayoutManagerProtocol> layoutManager;
}

@property (retain) id content;
@property (retain) Movie* hoveredMovie;
@property Class <MultiplexLayoutManagerProtocol> floorLayerLayoutManagerClass;

- (MovieLayer*) movieLayerForPoint:(CGPoint)p;

- (void) resetCurrentlySelectedMovieLayer;
- (void) setNoSelectedMovieLayer;

@end
