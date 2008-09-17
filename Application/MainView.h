#import <Cocoa/Cocoa.h>

@interface MainView : NSView {
    NSMutableDictionary* layersByID;
    NSMutableArray* listOfLayersInOrder;
    CALayer* floorLayer; // NR
    id content;
}

@property (retain) id content;

@end
