#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

@class Movie;
@class IndeterminateProgressIndicatorLayer;
@class Activity;

@interface MovieLayer : CALayer {
    CALayer* gradientLayer;
    CATiledLayer* boxImageLayer; 
    CALayer* smokeLayer;
    /**/
    Movie* movie;
    id boxArtImage;
    
    NSString* movieTitle;
}

@property (readonly) Movie* movie;
@property (retain) id boxArtImage;

+ (id) layerWithMovie:(Movie*)movie;

- (id) initWithMovie:(Movie*)movie;

@end
