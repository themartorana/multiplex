#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

@class Movie;
@class IndeterminateProgressIndicatorLayer;
@class Activity;

@interface MovieLayer : CALayer {
    Movie* movie;
    NSMutableData* imageData;
    
    CATextLayer* titleLayer;
    
    CATiledLayer* boxImageLayer; 
    CGImageRef boxImage;
    
    BOOL isHovered;
    
    Activity* activity;
}

@property (retain) Movie* movie;
@property (readwrite) BOOL isHovered;

@end
