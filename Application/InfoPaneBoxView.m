#import "InfoPaneBoxView.h"
#import "InfoPaneFormController.h"
#import "Movie.h"
#import <QuartzCore/QuartzCore.h>


@implementation InfoPaneBoxView

@synthesize selectedMovie;

- (void) awakeFromNib
{
    [self setWantsLayer:YES];
    [[self layer] setDelegate:self];
    
    [self bind:@"selectedMovie" toObject:controller withKeyPath:@"selectedMovie" options:nil];
}

- (void) setSelectedMovie:(Movie*)movie
{
    selectedMovie = movie;
    [[self layer] setNeedsDisplay];
}

- (void) drawLayer:(CALayer *)layer inContext:(CGContextRef)c
{
    CGImageRef frontCover = (CGImageRef)selectedMovie.frontCover;
    if (frontCover) {
        CGContextDrawImage(c, layer.bounds, frontCover);
    }
}

@end
