#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

#import "MultiplexLayoutManager.h"

@interface StadiumLayoutManager : NSObject <MultiplexLayoutManager> {
    CALayer* radialGradientLayer; // NR
    
    CALayer* hoveredMovieLayer;
    CALayer* hoverHighlightLayer;
    
    CATextLayer* titleLayer;
    
    NSArray* listOfLayersInOrder;
    NSArray* arrangedListOfObjects;
    
    BOOL dontLayoutBecauseOfHighlight;
}

@property (copy) NSArray* listOfLayersInOrder;

@end
