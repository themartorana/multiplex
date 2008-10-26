#import <Cocoa/Cocoa.h>
#import "Movie.h"
#import "MovieLayer.h"
#import "HoverPlayLayer.h"
#import "MultiplexLayoutManager.h"

@interface MainView : NSView {
    NSMutableDictionary* layersByID;
    NSMutableArray* listOfLayersInOrder;
    
    CALayer* floorLayer; // NR
    HoverPlayLayer* hoverPlayLayer;

    NSTrackingArea* mouseTrackingArea;
    
    id content;
    
    Movie* hoveredMovie;
    NSTimer* hoverTimer;
    
    BOOL needsLayout;
    
    Class <MultiplexLayoutManager> floorLayerLayoutManagerClass;
}

@property (retain) id content;
@property (retain) Movie* hoveredMovie;
@property Class <MultiplexLayoutManager> floorLayerLayoutManagerClass;

@end
