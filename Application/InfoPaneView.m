//
//  InfoPaneView.m
//  Multiplex
//
//  Created by David Martorana on 10/6/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "InfoPaneView.h"
#import "PlayButtonLayer.h"


@implementation InfoPaneView

- (void) awakeFromNib
{
    [self setWantsLayer:YES];
    [self layer].layoutManager = [CAConstraintLayoutManager layoutManager];
    [self layer].masksToBounds = NO;
    [self layer].cornerRadius = 20.0;
    [self layer].backgroundColor = CGColorCreateGenericRGB(0.0, 0.0, 0.0, 0.8);
    
    CALayer* borderLayer = [CALayer layer];
    borderLayer.borderColor = CGColorCreateGenericRGB(1.0, 1.0, 1.0, 0.6);
    borderLayer.borderWidth = 2.0;
    borderLayer.cornerRadius = 20.0;
    borderLayer.constraints = [NSArray arrayWithObjects:
                               [CAConstraint constraintWithAttribute:kCAConstraintMidX relativeTo:@"superlayer" attribute:kCAConstraintMidX],
                               [CAConstraint constraintWithAttribute:kCAConstraintMidY relativeTo:@"superlayer" attribute:kCAConstraintMidY],
                               [CAConstraint constraintWithAttribute:kCAConstraintWidth relativeTo:@"superlayer" attribute:kCAConstraintWidth],
                               [CAConstraint constraintWithAttribute:kCAConstraintHeight relativeTo:@"superlayer" attribute:kCAConstraintHeight],
                               nil];
    [[self layer] addSublayer:borderLayer];
    
    playButtonLayer = [[PlayButtonLayer layer] retain];
    playButtonLayer.anchorPoint = CGPointZero;
    playButtonLayer.zPosition = 1;
    playButtonLayer.constraints = [NSArray arrayWithObjects:
                                   [CAConstraint constraintWithAttribute:kCAConstraintMidX relativeTo:@"superlayer" attribute:kCAConstraintMaxX scale:1.0 offset:-40.0],
                                   [CAConstraint constraintWithAttribute:kCAConstraintMidY relativeTo:@"superlayer" attribute:kCAConstraintMinY scale:1.0 offset:40.0],
                                   [CAConstraint constraintWithAttribute:kCAConstraintWidth relativeTo:@"superlayer" attribute:kCAConstraintWidth scale:0.0 offset:200.0],
                                   [CAConstraint constraintWithAttribute:kCAConstraintHeight relativeTo:@"superlayer" attribute:kCAConstraintHeight scale:0.0 offset:200.0],
                                   nil];
    [[self layer] addSublayer:playButtonLayer];
    
    
}

@end
