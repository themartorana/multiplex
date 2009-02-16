#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

#import "MultiplexLayoutManagerProtocol.h"

@interface StadiumLayoutManager : NSObject <MultiplexLayoutManagerProtocol> {
    CALayer* floorLayer; // NR
    
    CALayer* radialGradientLayer; // NR
    CALayer* hoveredMovieLayer; // NR
    CALayer* selectedHighlightLayer; // NR
    CATextLayer* titleLayer; // NR

    CALayer* hoverHighlightLayer; // NR
    
    MovieLayer* selectedMovieLayer;
    
    NSArray* listOfLayersInOrder;
    
    BOOL layoutTriggeredDueToHover;
    BOOL shouldShowHiglightLayer;
    BOOL shouldShowHoverLayer;
}

@property (copy) NSArray* listOfLayersInOrder;

- (void) positionSelectedMovieLayer;

@end
