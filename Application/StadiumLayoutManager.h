#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

#import "MultiplexLayoutManager.h"

@interface StadiumLayoutManager : NSObject <MultiplexLayoutManager> {
    CALayer* radialGradientLayer; // NR
    
    CALayer* hoveredMovieLayer;
    CALayer* hoverHighlightLayer;
    
    CALayer* titleContainerLayer;
    CATextLayer* titleLayer;
    CATextLayer* titleReflectionLayer;
    
    NSArray* listOfLayersInOrder;
    NSArray* arrangedListOfObjects;
}

@end
