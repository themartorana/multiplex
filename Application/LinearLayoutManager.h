#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

#import "MultiplexLayoutManager.h"

@class Movie;

@interface LinearLayoutManager : NSObject <MultiplexLayoutManager> {
    CALayer* hoverHighlightLayer; // NR
    CALayer* selectedHighlightLayer; // NR
    CALayer* floorLayer;
    
    NSArray* listOfLayersInOrder;
    NSArray* arrangedListOfObjects;
    
    Movie* selectedMovie;
    
    BOOL dontLayoutBecauseOfHighlight;
    BOOL scrollToSelectedMovie;
}

@property (copy) NSArray* listOfLayersInOrder;

@end
