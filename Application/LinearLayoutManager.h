#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

#import "MultiplexLayoutManagerProtocol.h"

@class Movie;

@interface LinearLayoutManager : NSObject <MultiplexLayoutManagerProtocol> {
    CALayer* hoverHighlightLayer; // NR
    CALayer* selectedHighlightLayer; // NR
    CALayer* floorLayer;
    
    MovieLayer* selectedLayer;
    
    NSArray* listOfLayersInOrder;
    
    MovieLayer* selectedMovieLayer;
    
    BOOL dontLayoutBecauseOfHighlight;
    BOOL scrollToSelectedMovie;
    BOOL shouldShowHiglightLayer;
    BOOL shouldShowHoverLayer;
}

@property (copy) NSArray* listOfLayersInOrder;

@end
