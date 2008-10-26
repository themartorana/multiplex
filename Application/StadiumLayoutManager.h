#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

#import "MultiplexLayoutManager.h"

@interface StadiumLayoutManager : NSObject <MultiplexLayoutManager> {
    CALayer* floorLayer; // NR
    
    CALayer* radialGradientLayer; // NR
    CALayer* hoveredMovieLayer; // NR
    CATextLayer* titleLayer; // NR

    CALayer* hoverHighlightLayer; // NR

    NSArray* listOfLayersInOrder;
    NSArray* arrangedListOfObjects;
    
    BOOL dontLayoutBecauseOfHighlight;
}

@property (copy) NSArray* listOfLayersInOrder;

@end
