#import <Cocoa/Cocoa.h>
#import "Movie.h"
#import "MovieLayer.h"
#import "HoverPlayLayer.h"
#import "MultiplexLayoutManagerProtocol.h"

@class DrawerView;
@class ApplicationController;

extern NSString* const kMultiplexDrawerIsOpenLayoutManagerClass;
extern NSString* const kMultiplexDrawerIsClosedLayoutManagerClass;

@interface MainView : NSView {
    IBOutlet ApplicationController* applicationController;
    IBOutlet DrawerView* drawerView;
    
    NSMutableDictionary* layersByID;
    NSArray* listOfMoviesInOrder;
    
    CALayer* floorLayer; // NR
    HoverPlayLayer* hoverPlayLayer;

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

- (void) resetCurrentlySelectedMovieLayer;

@end
