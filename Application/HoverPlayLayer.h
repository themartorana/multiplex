#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

@class ButtonLayer;
@class Movie;

@interface HoverPlayLayer : CALayer {
    CALayer* surroundingLayer;
    CALayer* orangeBoxLayer;
    ButtonLayer* playButtonLayer; 
    
    CATextLayer* titleLayer;
    CATextLayer* additionalInfoLayer;
    
    Movie* hoveredMovie;
    
    BOOL isInAlternatePosition;
    BOOL isMouseDown;
}

@property (retain) Movie* hoveredMovie;
@property BOOL isMouseDown;

- (void) putLayersIntoDefaultPosition;
- (void) putLayersIntoAlternatePosition;

@end
