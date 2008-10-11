//
//  InfoPaneBoxView.m
//  Multiplex
//
//  Created by David Martorana on 10/8/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "InfoPaneBoxView.h"
#import "InfoPaneFormController.h"
#import "Movie.h"
#import "NSMutableDictionary+Mothership.h"
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

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)c
{
    CGImageRef img = [NSMutableDictionary boxImageForKey:selectedMovie.gtin];
    CGContextDrawImage(c, layer.bounds, img);
    CGImageRelease(img);
}

@end
