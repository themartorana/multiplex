#import <Cocoa/Cocoa.h>

@class Movie;
@class DiscPlayLayer;
@class PlayButtonLayer;

@interface InfoPaneDiscsView : NSView {
    Movie* selectedMovie;
    
    CALayer* viewLayer;
    CALayer* scrollingLayer;
    CALayer* discsHostingLayer;
    CALayer* pageNumbersLayer;
    
    NSTrackingArea* mouseTrackingArea;
    
    DiscPlayLayer* hoveredLayer;
    PlayButtonLayer* playButtonDownLayer;
}

@property (retain) Movie* selectedMovie;

- (void) setUpDiscLayers;
- (void) unhoverHoveredLayer;

@end
