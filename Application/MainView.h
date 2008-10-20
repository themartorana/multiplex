#import <Cocoa/Cocoa.h>
#import "Movie.h"
#import "MovieLayer.h"
#import "HoverPlayLayer.h"


@interface MainView : NSView {
    NSMutableDictionary* layersByID;
    NSMutableArray* listOfLayersInOrder;
    CALayer* floorLayer; // NR
    CALayer* radialGradientLayer; // NR
    
    CALayer* hoverHighlightLayer;
    HoverPlayLayer* hoverPlayLayer;
    
    CALayer* titleContainerLayer;
    CATextLayer* titleLayer;
    CATextLayer* titleReflectionLayer;
    
    NSTrackingArea* mouseTrackingArea;
    
    id content;
    
    Movie* hoveredMovie;
    NSTimer* hoverTimer;
    
    BOOL needsLayout;
}

@property (retain) id content;
@property (retain) Movie* hoveredMovie;

@end
