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
#import "Movie.h"
#import "CALayer+Mothership.h"

@implementation InfoPaneDiscsView

@synthesize selectedMovie;

- (void) awakeFromNib
{
    [self setWantsLayer:YES];
    scrollingLayer = [[CALayer layer] retain];
    discsHostingLayer = [[CALayer layer] retain];
    
    [discsHostingLayer addSublayer:scrollingLayer];
    discsHostingLayer.masksToBounds = YES;
    discsHostingLayer.anchorPoint = CGPointZero;
    
    scrollingLayer.anchorPoint = CGPointZero;
}

- (void) setSelectedMovie:(Movie*)_selectedMovie
{
    selectedMovie = _selectedMovie;
    [self setUpDiskLayers];
}

- (void) setUpDiskLayers
{
    float pageTextScaleFactor = 20.0;
    
    // Clear it out
    [[self layer] removeAllSublayers];
    
    int numDiscs = [selectedMovie.allDiscs count];
    
    if (!selectedMovie || numDiscs <=1)
        return;
    
    // Create page layers
    // Determine how many pages we need
    int numPages = ceil(((float)numDiscs)/6.0);
    
    if (numPages > 1) 
    {
        CALayer* pageNumbersLayer = [CALayer layer];
        [[self layer] addSublayer:pageNumbersLayer];
        pageNumbersLayer.anchorPoint = CGPointZero;
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
    discsHostingLayer.frame = CGRectMake(pageTextScaleFactor, 
                                0.0, 
                                [self layer].bounds.size.width,
                                [self layer].bounds.size.height - pageTextScaleFactor);
    
    // Set up the discs layer
    // Just keep pushing down, ceiling'd by two
    //scrollingLayer.bounds = (
    
    int numRows = ceil((float)numDiscs / 2.0);
    //scrollingLayer
}

@end
