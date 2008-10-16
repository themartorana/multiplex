#import <Cocoa/Cocoa.h>

@class Movie;
@class DiscPlayLayer;
@class ButtonLayer;

@interface InfoPaneDiscsView : NSView {
    Movie* selectedMovie;
    
    CALayer* viewLayer;
    CALayer* scrollingLayer;
    CALayer* discsHostingLayer;
    CALayer* pageNumbersLayer;
    
    NSTrackingArea* mouseTrackingArea;
    
    DiscPlayLayer* hoveredLayer;
    ButtonLayer* playButtonDownLayer;
}

@property (retain) Movie* selectedMovie;

- (void) setUpDiscLayers;
- (void) unhoverHoveredLayer;

@end
