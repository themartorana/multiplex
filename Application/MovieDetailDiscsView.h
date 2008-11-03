#import <Cocoa/Cocoa.h>

@class Movie;
@class DiscPlayLayer;
@class ButtonLayer;

@interface MovieDetailDiscsView : NSView {
    Movie* movie;
    
    CALayer* viewLayer;
    CALayer* scrollingLayer;
    CALayer* discsHostingLayer;
    CALayer* pageNumbersLayer;
    
    NSTrackingArea* mouseTrackingArea;
    
    DiscPlayLayer* hoveredLayer;
    ButtonLayer* playButtonDownLayer;
}

@property (retain) Movie* movie;

- (void) setUpDiscLayers;
- (void) unhoverHoveredLayer;

@end
