//
//  InfoView.m
//  Multiplex
//
//  Created by David Martorana on 9/29/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "InfoView.h"
#import "PlayButtonLayer.h"
#import "Disc.h"
#import "Media.h"
#import "InfoButtonLayer.h"

@implementation InfoView

@synthesize hoveredMovie;
@synthesize selectedMovies;
@synthesize numDiscsString;
@synthesize ratingString;
@synthesize movieTitleString;

+ (NSSet*) keyPathsForValuesAffectingValueForKey:(NSString*)key
{
    if ([key isEqualToString:@"numDiscsString"] ||
        [key isEqualToString:@"ratingString"] || 
        [key isEqualToString:@"movieTitleString"]) {
        return [NSSet setWithArray:[NSArray arrayWithObjects:@"selectedMovies", @"hoveredMovie", nil]];
    }
    
    return [super keyPathsForValuesAffectingValueForKey:key];
}

- (void) awakeFromNib
{
    self.wantsLayer = YES;
    
    // Set up the basic info layer
    [self setUpBasicInfoLayer];
    
    // Set up a tracking area
    mouseTrackingArea = [[NSTrackingArea alloc] initWithRect:NSRectFromCGRect([self layer].bounds) 
                                                     options:(NSTrackingMouseMoved|NSTrackingActiveAlways|NSTrackingInVisibleRect|NSTrackingMouseEnteredAndExited) 
                                                       owner:self 
                                                    userInfo:nil];
    [self addTrackingArea:mouseTrackingArea];
    
    // Bindings
    [titleLayer bind:@"string" toObject:self withKeyPath:@"movieTitleString" options:nil];
    [numDiscsLayer bind:@"string" toObject:self withKeyPath:@"numDiscsString" options:nil];
    [ratingLayer bind:@"string" toObject:self withKeyPath:@"ratingString" options:nil];
    [playButtonLayer bind:@"hidden" toObject:surroundingLayer withKeyPath:@"hidden" options:nil];
    [infoButtonLayer bind:@"hidden" toObject:surroundingLayer withKeyPath:@"hidden" options:nil];
}

- (NSString*) movieTitleString
{
    if (hoveredMovie) {
        return hoveredMovie.title;
    }
    else if (selectedMovies && [selectedMovies count] > 0) {
        return ((Movie*)[selectedMovies objectAtIndex:0]).title;
    }
    else {
        return @" ";
    }
}

- (NSString*) numDiscsString
{
    if (selectedMovies && [selectedMovies count] > 0) {
        Movie* m = [selectedMovies objectAtIndex:0];
        return [NSString stringWithFormat:@"%d discs", [m.allDiscs count]];
    }
    else
        return @" ";
}

- (NSString*) ratingString
{
    if (selectedMovies && [selectedMovies count] > 0) {
        Movie* m = [selectedMovies objectAtIndex:0];
        return [NSString stringWithFormat:@"Rating: %@", m.rating];
    }
    else
        return @" ";
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
                                  [CAConstraint constraintWithAttribute:kCAConstraintMaxY relativeTo:@"superlayer" attribute:kCAConstraintMaxY scale:1.0 offset:-20.0],
                                  nil];
    [[self layer] addSublayer:basicInfoLayer];
    basicInfoLayer.layoutManager = [CAConstraintLayoutManager layoutManager];
        
    
    // Set up the surrounding layer
    surroundingLayer = [[CALayer layer] retain];
    surroundingLayer.anchorPoint = CGPointZero;
    surroundingLayer.frame = CGRectMake(0.0, 0.0, 1.0, 1.0);
    surroundingLayer.hidden = YES;
    surroundingLayer.borderColor = CGColorCreateGenericRGB(1.0, 1.0, 1.0, 0.6);
    surroundingLayer.cornerRadius = 10.0;
    surroundingLayer.backgroundColor = CGColorCreateGenericRGB(0.0, 0.0, 0.0, 0.4);
    surroundingLayer.borderWidth = 2.0;
    surroundingLayer.name = @"surroundingLayer";
    surroundingLayer.constraints = [NSArray arrayWithObjects:
                                    [CAConstraint constraintWithAttribute:kCAConstraintMinX relativeTo:@"superlayer" attribute:kCAConstraintMinX],
                                    [CAConstraint constraintWithAttribute:kCAConstraintMinY relativeTo:@"superlayer" attribute:kCAConstraintMinY],
                                    [CAConstraint constraintWithAttribute:kCAConstraintWidth relativeTo:@"superlayer" attribute:kCAConstraintWidth],
                                    [CAConstraint constraintWithAttribute:kCAConstraintHeight relativeTo:@"superlayer" attribute:kCAConstraintHeight],
                                    nil];
    [basicInfoLayer addSublayer:surroundingLayer];
    
    
    // Set up the titleLayer
    titleLayer = [[CATextLayer layer] retain];
    titleLayer.anchorPoint = CGPointZero;
    titleLayer.wrapped = NO;
    titleLayer.alignmentMode = kCAAlignmentCenter;
    titleLayer.font = [NSFont boldSystemFontOfSize:20.0];
    titleLayer.fontSize = 20.0;
    titleLayer.constraints = [NSArray arrayWithObjects:
                              [CAConstraint constraintWithAttribute:kCAConstraintMidX relativeTo:@"superlayer" attribute:kCAConstraintMidX],
                              [CAConstraint constraintWithAttribute:kCAConstraintMaxY relativeTo:@"superlayer" attribute:kCAConstraintMaxY scale:1.0 offset:-9.0],
                              [CAConstraint constraintWithAttribute:kCAConstraintWidth relativeTo:@"superlayer" attribute:kCAConstraintWidth scale:0.9 offset:0.0],
                              nil];
    titleLayer.name = @"titleLayer";
    titleLayer.truncationMode = kCATruncationEnd;
    [basicInfoLayer addSublayer:titleLayer];

    // Add in all the information that will exist in the
    // surroundinLayer layer
    surroundingLayer.layoutManager = [CAConstraintLayoutManager layoutManager];
    
    // Add the number of discs
    numDiscsLayer = [[CATextLayer layer] retain];
    numDiscsLayer.fontSize = 12.0;
    numDiscsLayer.font = [NSFont boldSystemFontOfSize:12.0];
    numDiscsLayer.constraints = [NSArray arrayWithObjects:
                                 [CAConstraint constraintWithAttribute:kCAConstraintMinY relativeTo:@"superlayer" attribute:kCAConstraintMinY scale:1.0 offset:30.0],
                                 [CAConstraint constraintWithAttribute:kCAConstraintMinX relativeTo:@"superlayer" attribute:kCAConstraintMinX scale:1.0 offset:10.0],
                                 [CAConstraint constraintWithAttribute:kCAConstraintWidth relativeTo:@"superlayer" attribute:kCAConstraintWidth scale:0.4 offset:0.0],
                                 nil];
    numDiscsLayer.name = @"numDiscsLayer";
    numDiscsLayer.hidden = NO;
    [surroundingLayer addSublayer:numDiscsLayer];
    
    
    // Add the MPAA rating
    ratingLayer = [[CATextLayer layer] retain];
    ratingLayer.fontSize = 12.0;
    ratingLayer.font = [NSFont boldSystemFontOfSize:12.0];
    //MPAARatingLayer.borderColor = CGColorCreateGenericRGB(1.0, 0.0, 0.0, 1.0);
    //MPAARatingLayer.borderWidth = 1.0;
    ratingLayer.constraints = [NSArray arrayWithObjects:
                                   [CAConstraint constraintWithAttribute:kCAConstraintMinY relativeTo:@"superlayer" attribute:kCAConstraintMinY scale:1.0 offset:9.0],
                                   [CAConstraint constraintWithAttribute:kCAConstraintMinX relativeTo:@"superlayer" attribute:kCAConstraintMinX scale:1.0 offset:10.0],
                                   [CAConstraint constraintWithAttribute:kCAConstraintWidth relativeTo:@"superlayer" attribute:kCAConstraintWidth],
                                   nil];
    ratingLayer.name = @"MPAARatingLayer";
    [surroundingLayer addSublayer:ratingLayer];
    
    
    // Add the play button layer
    playButtonLayer = [[PlayButtonLayer layer] retain];
    playButtonLayer.constraints = [NSArray arrayWithObjects:
                                   [CAConstraint constraintWithAttribute:kCAConstraintMidX relativeTo:@"surroundingLayer" attribute:kCAConstraintMaxX],
                                   [CAConstraint constraintWithAttribute:kCAConstraintMidY relativeTo:@"surroundingLayer" attribute:kCAConstraintMinY scale:1.0 offset:18.0],
                                   [CAConstraint constraintWithAttribute:kCAConstraintWidth relativeTo:@"surroundingLayer" attribute:kCAConstraintWidth scale:0.0 offset:100.0],
                                   [CAConstraint constraintWithAttribute:kCAConstraintHeight relativeTo:@"surroundingLayer" attribute:kCAConstraintHeight scale:0.0 offset:100.0],
                                   nil];
    playButtonLayer.hidden = YES;
    [basicInfoLayer addSublayer:playButtonLayer];

    
    // Add the info button layer
    infoButtonLayer = [[InfoButtonLayer layer] retain];
    infoButtonLayer.constraints = [NSArray arrayWithObjects:
                                   [CAConstraint constraintWithAttribute:kCAConstraintMidX relativeTo:@"surroundingLayer" attribute:kCAConstraintMaxX],
                                   [CAConstraint constraintWithAttribute:kCAConstraintMidY relativeTo:@"surroundingLayer" attribute:kCAConstraintMinY scale:1.0 offset:18.0],
                                   [CAConstraint constraintWithAttribute:kCAConstraintWidth relativeTo:@"surroundingLayer" attribute:kCAConstraintWidth scale:0.0 offset:100.0],
                                   [CAConstraint constraintWithAttribute:kCAConstraintHeight relativeTo:@"surroundingLayer" attribute:kCAConstraintHeight scale:0.0 offset:100.0],
                                   nil];
    infoButtonLayer.hidden = YES;
    [basicInfoLayer addSublayer:infoButtonLayer];
    
}


- (void) mouseUp:(NSEvent*)theEvent
{
    CGPoint p = NSPointToCGPoint([self convertPoint:[theEvent locationInWindow] fromView:nil]);
    CALayer* layer = [[self layer] hitTest:p];
    if (layer == playButtonLayer) {
        
        Disc* d = [[[(Movie*)[selectedMovies objectAtIndex:0] allDiscs] allObjects] objectAtIndex:0];
        Media* m = [[(NSSet*)d.allMedia allObjects] objectAtIndex:0];
        
        if (m) {
            [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:m.url]];
        }
    }
}

- (void) mouseMoved:(NSEvent*)theEvent
{    
    CGPoint p = NSPointToCGPoint([self convertPoint:[theEvent locationInWindow] fromView:nil]);
    surroundingLayer.hidden = (nil == [basicInfoLayer hitTest:p] ||
                               (!selectedMovies || [selectedMovies count] <= 0));
}

- (void) mouseExited
{
    surroundingLayer.hidden = YES;
}

@end

























