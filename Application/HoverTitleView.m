#import "HoverTitleView.h"
#import "ButtonLayer.h"
#import "Disc.h"
#import "Media.h"
#import <Toolkit/Toolkit.h>
#import "CGColorFactory.h"

@implementation HoverTitleView

@synthesize hoveredMovie;

- (void) awakeFromNib
{
    self.wantsLayer = YES;
    
    // Set up the basic info layer
    [self setUpHoverTitleLayer];
    [titleReflectionLayer bind:@"string" toObject:titleLayer withKeyPath:@"string" options:nil];
}

- (void) setHoveredMovie:(Movie*) movie
{
    hoveredMovie = movie;
    
    if (hoveredMovie){
        titleLayer.string = movie.title;
    } else {
        titleLayer.string = @" ";
    }
}

///
/// Set up the information for our "basic" layer info
///
- (void) setUpHoverTitleLayer
{
    [[self layer] setLayoutManager:[CAConstraintLayoutManager layoutManager]];
    
    // Set up the basicInfoLayer that contains all of our basic info sublayers        
    
    // Set up the surrounding layer
    // Set up the titleLayer
    titleLayer = [[CATextLayer layer] retain];
    titleLayer.anchorPoint = CGPointZero;
    titleLayer.wrapped = NO;
    titleLayer.alignmentMode = kCAAlignmentCenter;
    titleLayer.font = [NSFont systemFontOfSize:40.0];
    titleLayer.fontSize = 40.0;
    titleLayer.name = @"titleLayer";
    titleLayer.constraints = [NSArray arrayWithObjects:
                              [CAConstraint constraintWithAttribute:kCAConstraintMidX relativeTo:@"superlayer" attribute:kCAConstraintMidX],
                              [CAConstraint constraintWithAttribute:kCAConstraintMaxY relativeTo:@"superlayer" attribute:kCAConstraintMaxY scale:1.0 offset:-9.0],
                              [CAConstraint constraintWithAttribute:kCAConstraintWidth relativeTo:@"superlayer" attribute:kCAConstraintWidth scale:0.0 offset:900.0],
                              nil];
    titleLayer.name = @"titleLayer";
    titleLayer.truncationMode = kCATruncationEnd;
    [[self layer] addSublayer:titleLayer];
    
    titleReflectionLayer = [[CATextLayer layer] retain];
    titleReflectionLayer.anchorPoint = CGPointZero;
    titleReflectionLayer.wrapped = NO;
    titleReflectionLayer.alignmentMode = kCAAlignmentCenter;
    titleReflectionLayer.font = [NSFont systemFontOfSize:40.0];
    titleReflectionLayer.fontSize = 40.0;
    titleReflectionLayer.foregroundColor = [CGColorFactory white];
    titleReflectionLayer.name = @"titleReflectionLayer";
    titleReflectionLayer.transform = CATransform3DMakeScale(1.0, -1.0, 1.0);
    titleReflectionLayer.constraints = [NSArray arrayWithObjects:
                                        [CAConstraint constraintWithAttribute:kCAConstraintMidX relativeTo:@"superlayer" attribute:kCAConstraintMidX],
                                        [CAConstraint constraintWithAttribute:kCAConstraintMaxY relativeTo:@"titleLayer" attribute:kCAConstraintMinY scale:1.0 offset:14.0],
                                        [CAConstraint constraintWithAttribute:kCAConstraintWidth relativeTo:@"superlayer" attribute:kCAConstraintWidth scale:0.0 offset:900.0],
                                        nil];
    titleReflectionLayer.name = @"titleReflectionLayer";
    titleReflectionLayer.truncationMode = kCATruncationEnd;

    [titleReflectionLayer setMask:[CALayer maskLayer]];
    [[self layer] addSublayer:titleReflectionLayer];
}


@end

