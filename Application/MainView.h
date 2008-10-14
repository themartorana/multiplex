#import <Cocoa/Cocoa.h>
#import "Movie.h"
#import "MovieLayer.h"
#import "HoverPlayLayer.h"


@interface MainView : NSView {
    NSMutableDictionary* layersByID;
    NSMutableArray* listOfLayersInOrder;
    CALayer* floorLayer; // NR
    CALayer* radialGradientLayer; // NR
    
    CALayer* highlightLayer;
    
    HoverPlayLayer* hoverPlayLayer;
    
    NSTrackingArea* mouseTrackingArea;
    
    id content;
    
    Movie* hoveredMovie;
    
    NSTimer* hoverTimer;
    
    NSPoint lastKnownMouseCoordinates;
}

@property (retain) id content;
@property (retain) Movie* hoveredMovie;

- (void) pauseTracking;
- (void) resumeTracking;

@end
