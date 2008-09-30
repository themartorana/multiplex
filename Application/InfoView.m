//
//  InfoView.m
//  Multiplex
//
//  Created by David Martorana on 9/29/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "InfoView.h"


@implementation InfoView

@synthesize hoveredMovie;
@synthesize selectedMovies;
@synthesize hoveredOrSelectedMovie;

+ (NSSet*) keyPathsForValuesAffectingValueForKey:(NSString*)key
{
    if ([key isEqualToString:@"hoveredOrSelectedMovie"]) {
        return [NSSet setWithArray:[NSArray arrayWithObjects:@"selectedMovies", @"hoveredMovie", nil]];
    }
    return [super keyPathsForValuesAffectingValueForKey:key];
}

- (void) awakeFromNib
{
    // Set up the basic info layer
    [self setUpBasicInfoLayer];
    
    // Set up a tracking area
    mouseTrackingArea = [[NSTrackingArea alloc] initWithRect:NSRectFromCGRect([self layer].bounds) 
                                                     options:(NSTrackingMouseMoved|NSTrackingActiveAlways|NSTrackingInVisibleRect) 
                                                       owner:self 
                                                    userInfo:nil];
    [self addTrackingArea:mouseTrackingArea];
    
    // Bindings
    [titleLayer bind:@"string" toObject:self withKeyPath:@"hoveredOrSelectedMovie.title" options:nil];
}


///
/// A "fake" property for our fun bindings
///
- (Movie*) hoveredOrSelectedMovie
{
    if (hoveredMovie) {
        return hoveredMovie;
    }
    else {
        if ([selectedMovies count] > 0) {
            return (Movie*)[selectedMovies objectAtIndex:0];
        }
        else {
            return nil;
        }
    }
}


///
/// Set up the information for our "basic" layer info
///
- (void) setUpBasicInfoLayer
{
    /*
    CALayer* basicInfoLayer;
    CALayer* titleHostingLayer;
    CATextLayer* titleLayer;
    CATextLayer* selectedTextLayer;
    CALayer* secondaryInfoLayer;
    CATextLayer* numDiscsLayer;
    CATextLayer* MPAARatingLayer;
    CALayer* playButtonLayer;
    CALayer* infoButtonLayer;
    */
    [[self layer] setLayoutManager:[CAConstraintLayoutManager layoutManager]];
    
    // Set up the basicInfoLayer that contains all of our basic info sublayers
    basicInfoLayer = [[CALayer layer] retain];
    basicInfoLayer.anchorPoint = CGPointZero;
    basicInfoLayer.frame = CGRectMake(0.0, 0.0, [self layer].bounds.size.width, 80.0);
    basicInfoLayer.borderColor = CGColorCreateGenericRGB(1.0, 0.0, 0.0, 1.0);
    //basicInfoLayer.borderWidth = 2.0;
    basicInfoLayer.constraints = [NSArray arrayWithObjects:
                                  [CAConstraint constraintWithAttribute:kCAConstraintMidX relativeTo:@"superlayer" attribute:kCAConstraintMidX],
                                  [CAConstraint constraintWithAttribute:kCAConstraintWidth relativeTo:@"superlayer" attribute:kCAConstraintWidth scale:0.0 offset:500.0],
                                  [CAConstraint constraintWithAttribute:kCAConstraintHeight relativeTo:@"superlayer" attribute:kCAConstraintHeight scale:0.0 offset:80.0],
                                  [CAConstraint constraintWithAttribute:kCAConstraintMaxY relativeTo:@"superlayer" attribute:kCAConstraintMaxY scale:1.0 offset:-10.0],
                                  nil];
    [[self layer] addSublayer:basicInfoLayer];
    basicInfoLayer.layoutManager = [CAConstraintLayoutManager layoutManager];
        
    // Set up the selected text layer
    /*selectedTextLayer = [[CATextLayer layer] retain];
    selectedTextLayer.anchorPoint = CGPointZero;
    selectedTextLayer.string = @"- selected -";
    selectedTextLayer.hidden = YES;
    selectedTextLayer.constraints = [NSArray arrayWithObjects:
                                     [CAConstraint constraintWithAttribute:kCAConstraintMaxY relativeTo:@"superlayer" attribute:kCAConstraintMaxY scale:1.0 offset:-5.0],
                                     [CAConstraint constraintWithAttribute:kCAConstraintWidth relativeTo:@"superlayer" attribute:kCAConstraintWidth],
                                     [CAConstraint constraintWithAttribute:kCAConstraintMidX relativeTo:@"superlayer" attribute:kCAConstraintMidX],
                                     nil];
    selectedTextLayer.wrapped = NO;
    selectedTextLayer.alignmentMode = kCAAlignmentCenter;
    selectedTextLayer.fontSize = 14.0;
    selectedTextLayer.name = @"selectedTextLayer";
    [basicInfoLayer addSublayer:selectedTextLayer];
    */
    
    // Set up the surrounding layer
    surroundingLayer = [[CALayer layer] retain];
    surroundingLayer.anchorPoint = CGPointZero;
    surroundingLayer.frame = CGRectMake(0.0, 0.0, 1.0, 1.0);
    surroundingLayer.hidden = YES;
    surroundingLayer.borderColor = CGColorCreateGenericRGB(1.0, 1.0, 1.0, 0.6);
    surroundingLayer.cornerRadius = 10.0;
    surroundingLayer.backgroundColor = CGColorCreateGenericRGB(0.0, 0.0, 0.0, 0.4);
    surroundingLayer.borderWidth = 2.0;
    surroundingLayer.constraints = [NSArray arrayWithObjects:
                                    [CAConstraint constraintWithAttribute:kCAConstraintMinX relativeTo:@"superlayer" attribute:kCAConstraintMinX],
                                    [CAConstraint constraintWithAttribute:kCAConstraintMinY relativeTo:@"superlayer" attribute:kCAConstraintMinY],
                                    [CAConstraint constraintWithAttribute:kCAConstraintWidth relativeTo:@"superlayer" attribute:kCAConstraintWidth],
                                    [CAConstraint constraintWithAttribute:kCAConstraintHeight relativeTo:@"superlayer" attribute:kCAConstraintHeight],
                                    nil];
    [basicInfoLayer addSublayer:surroundingLayer];
                                     
    // Set up the titleHostingLayer
    titleHostingLayer = [[CALayer layer] retain];
    titleHostingLayer.anchorPoint = CGPointZero;
    titleHostingLayer.frame = CGRectMake(0.0, 0.0, 0.0, 50.0);
    titleHostingLayer.constraints = [NSArray arrayWithObjects:
                                     [CAConstraint constraintWithAttribute:kCAConstraintMidY relativeTo:@"superlayer" attribute:kCAConstraintMidY],
                                     [CAConstraint constraintWithAttribute:kCAConstraintWidth relativeTo:@"superlayer" attribute:kCAConstraintWidth scale:0.8 offset:0.0],
                                     [CAConstraint constraintWithAttribute:kCAConstraintMidX relativeTo:@"superlayer" attribute:kCAConstraintMidX],
                                     nil];
    titleHostingLayer.name = @"titleHostingLayer";
    [basicInfoLayer addSublayer:titleHostingLayer];
    
    // Set up the titleLayer
    titleLayer = [[CATextLayer layer] retain];
    titleLayer.anchorPoint = CGPointZero;
    titleLayer.wrapped = YES;
    titleLayer.alignmentMode = kCAAlignmentCenter;
    titleLayer.font = [NSFont boldSystemFontOfSize:20.0];
    titleLayer.fontSize = 20.0;
    titleLayer.name = @"titleLayer";
    titleLayer.autoresizingMask = kCALayerWidthSizable;
    titleLayer.truncationMode = kCATruncationEnd;
    [titleHostingLayer addSublayer:titleLayer];
    titleLayer.bounds = titleLayer.superlayer.bounds;
    
    // Set up the secondaryInfoLayer which will hold our number of discs as
    // well as our ratings layer
    
    // Add the number of discs
    
    numDiscsLayer = [[CATextLayer layer] retain];
    numDiscsLayer.fontSize = 12.0;
    numDiscsLayer.constraints = [NSArray arrayWithObjects:
                                 [CAConstraint constraintWithAttribute:kCAConstraintMaxY relativeTo:@"titleHostingLayer" attribute:kCAConstraintMinY],
                                 [CAConstraint constraintWithAttribute:kCAConstraintMinX relativeTo:@"titleHostingLayer" attribute:kCAConstraintMinX],
                                 [CAConstraint constraintWithAttribute:kCAConstraintWidth relativeTo:@"titleHostingLayer" attribute:kCAConstraintWidth scale:0.5 offset:0.0],
                                 nil];
    numDiscsLayer.name = @"numDiscsLayer";
    [basicInfoLayer addSublayer:numDiscsLayer];
    
    // Add the MPAA rating
    MPAARatingLayer = [[CATextLayer layer] retain];
    MPAARatingLayer.fontSize = 12.0;
    MPAARatingLayer.constraints = [NSArray arrayWithObjects:
                                   [CAConstraint constraintWithAttribute:kCAConstraintMaxX relativeTo:@"titleHostingLayer" attribute:kCAConstraintMaxX],
                                   [CAConstraint constraintWithAttribute:kCAConstraintWidth relativeTo:@"titleHostingLayer" attribute:kCAConstraintWidth scale:0.5 offset:0.0],
                                   nil];
    MPAARatingLayer.name = @"MPAARatingLayer";
    [basicInfoLayer addSublayer:MPAARatingLayer];
}


- (void) mouseUp:(NSEvent*)theEvent
{
    CGPoint p = NSPointToCGPoint([self convertPoint:[theEvent locationInWindow] fromView:nil]);
    CALayer* layer = [[self layer] hitTest:p];

}

- (void) mouseMoved:(NSEvent*)theEvent
{    
    CGPoint p = NSPointToCGPoint([self convertPoint:[theEvent locationInWindow] fromView:nil]);

    surroundingLayer.hidden = nil == [basicInfoLayer hitTest:p];
}

@end

























