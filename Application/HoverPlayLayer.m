//
//  HoverPlayLayer.m
//  Multiplex
//
//  Created by David Martorana on 10/14/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "HoverPlayLayer.h"
#import "Movie.h"
#import "NSColor+Mothership.h"
#import "PlayButtonLayer.h"
#import <QuartzCore/QuartzCore.h>


@implementation HoverPlayLayer

@synthesize hoveredMovie;

- (HoverPlayLayer*) init
{
    if (self = [super init]) {
        [self setUpLayerLayout];        
    }

    return self;
}

- (void) setUpLayerLayout
{
    self.anchorPoint = CGPointZero;
    self.frame = CGRectMake(0.0, 0.0, 360.0, 90.0);
    self.layoutManager = [CAConstraintLayoutManager layoutManager];
    
    orangeBoxLayer = [CALayer layer];
    orangeBoxLayer.anchorPoint = CGPointZero;
    orangeBoxLayer.bounds = CGRectMake(0.0, 0.0, 285.0, 70.0);
    orangeBoxLayer.backgroundColor = [[NSColor colorWithRGBIn0To255ValuesForRed:230 
                                                                          green:112 
                                                                           blue:51
                                                                          alpha:240] colorAsCGColorRef];
    orangeBoxLayer.borderColor = [[NSColor colorWithRGBIn0To255ValuesForRed:230 
                                                                      green:112 
                                                                       blue:51 
                                                                      alpha:255] colorAsCGColorRef];
    orangeBoxLayer.borderWidth = 2.0;
    orangeBoxLayer.cornerRadius = 10.0;
    [self addSublayer:orangeBoxLayer];
    
    playButtonLayer = [PlayButtonLayer layer];
    playButtonLayer.anchorPoint = CGPointZero;
    playButtonLayer.bounds = CGRectMake(0.0, 0.0, 92.0, 92.0);
    [self addSublayer:playButtonLayer];
    
    titleLayer = [CATextLayer layer];
    titleLayer.anchorPoint = CGPointZero;
    titleLayer.bounds = CGRectMake(0.0, 0.0, 220.0, 32.0);
    titleLayer.borderColor = CGColorCreateGenericRGB(0.0, 0.0, 1.0, 1.0);
    titleLayer.borderWidth = 1.0;
    titleLayer.font = [NSFont boldSystemFontOfSize:12.0];
    titleLayer.fontSize = 12.0;
    titleLayer.wrapped = YES;
    [orangeBoxLayer addSublayer:titleLayer];
    
    runningTimeLayer = [CATextLayer layer];
    runningTimeLayer.anchorPoint = CGPointZero;
    [orangeBoxLayer addSublayer:runningTimeLayer];
    
    ratingsLayer = [CATextLayer layer];
    ratingsLayer.anchorPoint = CGPointZero;
    [orangeBoxLayer addSublayer:ratingsLayer];
    
    // There are two ways to position the layers.  
    // We'll go with the default at first.
    [self putLayersIntoDefaultPosition];
}

- (void) setPosition:(CGPoint)position
{
    if (position.x + self.bounds.size.width < [[NSApp keyWindow] frame].size.width) {
        [self putLayersIntoDefaultPosition];
        [super setPosition:position];
    }
    else {
        [self putLayersIntoAlternatePosition];
        [super setPosition:CGPointMake(position.x - self.bounds.size.width, position.y)];
    }
}

- (void) putLayersIntoDefaultPosition
{
    self.layoutManager = [CAConstraintLayoutManager layoutManager];
    
    // Put the play button to the left
    playButtonLayer.constraints = [NSArray arrayWithObjects:
                                   [CAConstraint constraintWithAttribute:kCAConstraintMinX relativeTo:@"superlayer" attribute:kCAConstraintMinX],
                                   [CAConstraint constraintWithAttribute:kCAConstraintMidY relativeTo:@"superlayer" attribute:kCAConstraintMidY],
                                   nil];
    
    orangeBoxLayer.constraints = [NSArray arrayWithObjects:
                                  [CAConstraint constraintWithAttribute:kCAConstraintMinX relativeTo:@"superlayer" attribute:kCAConstraintMinX scale:1.0 offset:46.0],
                                  [CAConstraint constraintWithAttribute:kCAConstraintMidY relativeTo:@"superlayer" attribute:kCAConstraintMidY],
                                  nil];
    
    titleLayer.position = CGPointMake(50.0, 30.0);
    
    [self setNeedsLayout];
}

- (void) putLayersIntoAlternatePosition
{
    isInAlternatePosition = YES;
    
    // Put the play button to the left
    playButtonLayer.constraints = [NSArray arrayWithObjects:
                                   [CAConstraint constraintWithAttribute:kCAConstraintMaxX relativeTo:@"superlayer" attribute:kCAConstraintMaxX],
                                   [CAConstraint constraintWithAttribute:kCAConstraintMidY relativeTo:@"superlayer" attribute:kCAConstraintMidY],
                                   nil];
    
    orangeBoxLayer.constraints = [NSArray arrayWithObjects:
                                  [CAConstraint constraintWithAttribute:kCAConstraintMaxX relativeTo:@"superlayer" attribute:kCAConstraintMaxX scale:1.0 offset:-46.0],
                                  [CAConstraint constraintWithAttribute:kCAConstraintMidY relativeTo:@"superlayer" attribute:kCAConstraintMidY],
                                  nil];
    
    [self setNeedsLayout];
}

- (void) setHoveredMovie:(Movie*)movie 
{
    hoveredMovie = movie;
    
    if (hoveredMovie) {
        titleLayer.string = hoveredMovie.title;
    }
    
}

@end














