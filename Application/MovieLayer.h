#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

@class CATextLayer;
@class CATiledLayer;
@class Movie;
@class IndeterminateProgressIndicatorLayer;
@class Activity;

@interface MovieLayer : CALayer {
    CATextLayer* titleLayer;
    CATiledLayer* boxImageLayer; 
    /**/
    Movie* movie;
    CGImageRef boxImage;
}

@property (readonly) Movie* movie;
@property CGImageRef boxImage;

+ (id) layerWithMovie:(Movie*)movie;

- (id) initWithMovie:(Movie*)movie;

@end
