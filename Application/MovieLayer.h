#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

@class Movie;
@class IndeterminateProgressIndicatorLayer;

@interface MovieLayer : CALayer {
    Movie* movie;
    NSMutableData* imageData;
    IndeterminateProgressIndicatorLayer* spinnerLayer;
    CATiledLayer* boxImageLayer; 
    CGImageRef boxImage;
}

@property (retain) Movie* movie;

@end
