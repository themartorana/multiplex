#import <QuartzCore/QuartzCore.h>

@class Movie;

@interface MovieLayer : CALayer {
    Movie* movie;
    NSMutableData* imageData;
}

@property (retain) Movie* movie;

@end
