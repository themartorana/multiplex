#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

@class Movie;
@class IndeterminateProgressIndicatorLayer;
@class Activity;

@interface MovieLayer : CALayer {
    CALayer* gradientLayer;
    CATextLayer* titleLayer;
    CATiledLayer* boxImageLayer; 
    /**/
    Movie* movie;
    id boxImage;
}

@property (readonly) Movie* movie;
@property (retain) id boxImage;

+ (id) layerWithMovie:(Movie*)movie;

- (id) initWithMovie:(Movie*)movie;

@end
