#import <Cocoa/Cocoa.h>
#import "Movie.h"
#import "MovieLayer.h"

@interface MainView : NSView {
    NSMutableDictionary* layersByID;
    NSMutableArray* listOfLayersInOrder;
    CALayer* floorLayer; // NR
    CALayer* radialGradientLayer; // NR
    
    CALayer* highlightLayer;
    
    NSTrackingArea* mouseTrackingArea;
    
    id content;
    
    Movie* hoveredMovie;
}

@property (retain) id content;
@property (retain) Movie* hoveredMovie;

@end
