#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

@class Movie;
@class IndeterminateProgressIndicatorLayer;
@class Activity;

@interface MovieLayer : CALayer {
    CALayer* gradientLayer;
    CATiledLayer* boxImageLayer; 
    CALayer* smokeLayer;
    CALayer* setIndicatorLayer;
    //CATextLayer* setInformationLayer;
    /**/
    Movie* movie;
    id boxArtImage;
    
    NSString* movieTitle;
}

@property (retain) Movie* movie;
@property (retain) id boxArtImage;

@property (retain) MovieLayer* upLayer;
@property (retain) MovieLayer* downLayer;

+ (id) layerWithMovie:(Movie*)movie;

- (void) clearMoveData;

@end
