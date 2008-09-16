#import <Cocoa/Cocoa.h>

@interface MainView : NSView {
    NSMutableDictionary* layersByID;
    NSMutableArray* layersInOrder;
    CALayer* floorLayer; // NR
    id content;
    int totalCount;
}

@property (retain) id content;

@end
