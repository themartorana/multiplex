#import <Cocoa/Cocoa.h>
#import "MultiplexLayoutManager.h"

@class Movie;

@interface CoverFlowLayoutManager : NSObject <MultiplexLayoutManager> {
    NSArray* listOfLayersInOrder;
    NSArray* arrangedListOfObjects;
    
    CALayer* hoveredMovieLayer;
    CALayer* floorLayer;

    CALayer* hoverHighlightLayer;
    CALayer* selectedHighlightLayer;
    
    Movie* selectedMovie;
    BOOL scrollToSelectedMovie;
    float scrollToPoint;
}

@end
