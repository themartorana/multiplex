#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

#import "MultiplexLayoutManager.h"

@interface CoverFlowLayoutManager2 : NSObject <MultiplexLayoutManager> {
    CALayer* hoverHighlightLayer; // NR
    
    NSArray* listOfLayersInOrder;
    NSArray* arrangedListOfObjects;
    
    BOOL dontLayoutBecauseOfHighlight;
}

@property (copy) NSArray* listOfLayersInOrder;

@end
