#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

@class Movie;
@class IndeterminateProgressIndicatorLayer;

@interface MovieLayer : CALayer {
    Movie* movie;
    NSMutableData* imageData;
    IndeterminateProgressIndicatorLayer* spinnerLayer;
    
    CATextLayer* titleLayer;
    
    CATiledLayer* boxImageLayer; 
    CGImageRef boxImage;
    
    BOOL isHovered;
}

@property (retain) Movie* movie;
@property (readwrite) BOOL isHovered;

@end
