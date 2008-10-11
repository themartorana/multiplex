//
//  InfoPaneDisksView.m
//  Multiplex
//
//  Created by David Martorana on 10/8/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "InfoPaneDiscsView.h"
#import "PageNumberLayer.h"
#import "DiscPlayLayer.h"
#import "PlayButtonLayer.h"
#import "Movie.h"
#import "Disc.h"
#import "CALayer+Mothership.h"

@implementation InfoPaneDiscsView

@synthesize selectedMovie;

- (void) awakeFromNib
{
    
    viewLayer = [[CALayer layer] retain];
    viewLayer.anchorPoint = CGPointZero;
    viewLayer.frame = [[self layer] frame];
    [self setLayer:viewLayer];
    [self setWantsLayer:YES];
    
    [viewLayer bind:@"bounds" toObject:self withKeyPath:@"bounds" options:nil];

    scrollingLayer = [[CALayer layer] retain];
    discsHostingLayer = [[CALayer layer] retain];
    [self layer].anchorPoint = CGPointZero;
    [[self layer] addSublayer:discsHostingLayer];
    
    [discsHostingLayer addSublayer:scrollingLayer];
    discsHostingLayer.masksToBounds = YES;
    discsHostingLayer.anchorPoint = CGPointZero;
    //discsHostingLayer.borderColor = CGColorCreateGenericRGB(1.0, 0.0, 0.0, 1.0);
    //discsHostingLayer.borderWidth = 2.0;
    
    discsHostingLayer.frame = CGRectMake(20.0, 
                                         30.0, 
                                         [self layer].bounds.size.width - 40.0,
                                         [self layer].bounds.size.height - 40.0);
    
    scrollingLayer.anchorPoint = CGPointZero;
    
    pageNumbersLayer = [CALayer layer];
    pageNumbersLayer.anchorPoint = CGPointZero;
    [[self layer] addSublayer:pageNumbersLayer];
    
    // Set up the tracking stuff
    mouseTrackingArea = [[NSTrackingArea alloc] initWithRect:NSRectFromCGRect([self layer].bounds) 
                                                     options:(NSTrackingMouseMoved|NSTrackingActiveWhenFirstResponder|NSTrackingInVisibleRect|NSTrackingMouseEnteredAndExited) 
                                                       owner:self 
                                                    userInfo:nil];
    [self addTrackingArea:mouseTrackingArea];
}

- (void) setSelectedMovie:(Movie*)_selectedMovie
{
    selectedMovie = _selectedMovie;
    [self setUpDiscLayers];
}

- (void) setUpDiscLayers
{
    float pageTextScaleFactor = 20.0;
    
    // Clear it out
    [discsHostingLayer removeAllSublayers];
    [scrollingLayer removeAllSublayers];
    [pageNumbersLayer removeAllSublayers];
    [discsHostingLayer addSublayer:scrollingLayer];
    
    int numDiscs = [selectedMovie.allDiscs count];
    
    if (!selectedMovie || numDiscs <1)
        return;
    
    // Create page layers
    // Determine how many pages we need
    int numPages = ceil(((float)numDiscs)/6.0);
    
    if (numPages > 1) 
    {
        pageNumbersLayer.frame = CGRectMake(([self layer].bounds.size.width / 2.0) - ((pageTextScaleFactor * (float)numPages) / 2.0), 
                                            0.0, 
                                            pageTextScaleFactor * numPages, 
                                            pageTextScaleFactor);
        
        for (int i = 0; i < numPages; i++) {
            PageNumberLayer* pnLayer = [PageNumberLayer layer];
            pnLayer.pageNumber = i + 1;
            pnLayer.anchorPoint = CGPointZero;
            pnLayer.frame = CGRectMake(i * pageTextScaleFactor, 0.0, pageTextScaleFactor, pageTextScaleFactor);
            [pageNumbersLayer addSublayer:pnLayer];
        }
    }

    // Set up the scrolling layer
    scrollingLayer.anchorPoint = CGPointZero;
    scrollingLayer.frame = CGRectMake(0.0, 0.0, numPages * discsHostingLayer.bounds.size.width, discsHostingLayer.bounds.size.height);
    
    //int numRows = ceil((float)numDiscs / 2.0);
    int currentRow = 1;
    int currentPage = 1;
    
    // Get our discs in order
    NSMutableArray* discs = [NSMutableArray arrayWithArray:[selectedMovie.allDiscs allObjects]];
    [discs sortUsingDescriptors:[NSArray arrayWithObject:[[[NSSortDescriptor alloc] initWithKey:@"number" ascending:YES] autorelease]]];
    
    // Lay out our discs
    for (int i = 0; i < [discs count]; i++) {
        Disc* disc = [discs objectAtIndex:i];
                
        DiscPlayLayer* dpLayer = [DiscPlayLayer layer];
        [dpLayer setDisc:disc];
        
        float x = 0.0;
        float y = 0.0;
        
        if ((i+1) % 2 == 0) {
            x = discsHostingLayer.bounds.size.width - dpLayer.bounds.size.width;
        }
        x += (currentPage - 1) * discsHostingLayer.bounds.size.width;
        
        y = scrollingLayer.bounds.size.height - (currentRow * dpLayer.bounds.size.height) - (currentRow * 10.0);
        
        dpLayer.frame = CGRectMake(x, y, dpLayer.bounds.size.width, dpLayer.bounds.size.height);
                
        [scrollingLayer addSublayer:dpLayer];
        
        if (i != 0 && ((i+1) % 2) == 0) {
            currentRow ++;
        }
        if (currentRow == 4) {
            currentRow = 1;
            currentPage ++;
        }
    }
}

- (void) unhoverHoveredLayer
{
    if (hoveredLayer) {
        hoveredLayer.hovered = NO;
        hoveredLayer = nil;
    } 
}

- (void) mouseMoved:(NSEvent*)theEvent
{
    CGPoint p = NSPointToCGPoint([self convertPoint:[theEvent locationInWindow] fromView:nil]);
    CALayer* layer = [discsHostingLayer hitTest:p];
    
    if (layer) {
        // Look for a DiscPlayLayer
        while (layer && ![layer isKindOfClass:[DiscPlayLayer class]]) {
            layer = layer.superlayer;
        }
        
        if (layer) {
            if (!((DiscPlayLayer*)layer).hovered) {
                [self unhoverHoveredLayer];
                ((DiscPlayLayer*)layer).hovered = YES;
                hoveredLayer = (DiscPlayLayer*)layer;
            }
        }
        else {
            [self unhoverHoveredLayer];
        }
    }
    else {
        [self unhoverHoveredLayer];
        
        layer = [pageNumbersLayer hitTest:p];
    }
}

- (void) mouseDown:(NSEvent*)theEvent
{
    CGPoint p = NSPointToCGPoint([self convertPoint:[theEvent locationInWindow] fromView:nil]);
    CALayer* layer = [discsHostingLayer hitTest:p];
    
    if ([layer isKindOfClass:[PlayButtonLayer class]]) {
        ((PlayButtonLayer*)layer).isMouseDown = YES;
        playButtonDownLayer = (PlayButtonLayer*)layer;
    }
}

- (void) mouseUp:(NSEvent*)theEvent
{
    CGPoint p = NSPointToCGPoint([self convertPoint:[theEvent locationInWindow] fromView:nil]);
    CALayer* layer = [discsHostingLayer hitTest:p];
    
    if (layer) {
        if ([layer isKindOfClass:[PlayButtonLayer class]] && layer == playButtonDownLayer) {
            DiscPlayLayer* dpLayer = (DiscPlayLayer*)layer.superlayer;
            Disc* disc = dpLayer.disc;
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"MultiplexPlayDisc" object:disc];
        }    
    }
    else {
        layer = [pageNumbersLayer hitTest:p];

        if (layer && [layer.superlayer isKindOfClass:[PageNumberLayer class]]) {
            int pgNum = ((PageNumberLayer*)[layer superlayer]).pageNumber;
            scrollingLayer.position = CGPointMake((pgNum - 1) * discsHostingLayer.bounds.size.width * -1.0, 0);
        }
    }

    if (playButtonDownLayer) {
        playButtonDownLayer.isMouseDown = NO;
        playButtonDownLayer = nil;
    }
}

- (void)mouseExited:(NSEvent *)theEvent
{
    [self unhoverHoveredLayer];
    if (playButtonDownLayer) {
        playButtonDownLayer.isMouseDown = NO;
        playButtonDownLayer = nil;
    }
}

@end
