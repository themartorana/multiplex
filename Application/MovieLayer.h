#import <QuartzCore/QuartzCore.h>

@class Movie;

@interface MovieLayer : CALayer {
    Movie* movie;
}

@property (retain) Movie* movie;

@end
