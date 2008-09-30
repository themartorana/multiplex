#import <Cocoa/Cocoa.h>
#import "Movie.h"

@interface MainView : NSView {
    NSMutableDictionary* layersByID;
    NSMutableArray* listOfLayersInOrder;
    CALayer* floorLayer; // NR
    CALayer* radialGradientLayer; // NR
    
    NSTrackingArea* mouseTrackingArea;
    
    id content;
    
    Movie* hoveredMovie;
}

@property (retain) id content;
@property (retain) Movie* hoveredMovie;

@end
