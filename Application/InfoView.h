//
//  InfoView.h
//  Multiplex
//
//  Created by David Martorana on 9/29/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import "Movie.h"

@interface InfoView : NSView {
    NSArray* selectedMovies;
    Movie* hoveredMovie;
    Movie* hoveredOrSelectedMovie;
    
    /* Layers for basic info */
    CALayer* basicInfoLayer;
    CALayer* surroundingLayer;
    CALayer* titleHostingLayer;
    CATextLayer* titleLayer;
    CATextLayer* selectedTextLayer;
    CALayer* secondaryInfoLayer;
    CATextLayer* numDiscsLayer;
    CATextLayer* MPAARatingLayer;
    CALayer* playButtonLayer;
    CALayer* infoButtonLayer;
    
    NSTrackingArea* mouseTrackingArea;
}

@property (readwrite, retain) NSArray* selectedMovies;
@property (readwrite, retain) Movie* hoveredMovie;
@property (readwrite, retain) Movie* hoveredOrSelectedMovie;

- (void) setUpBasicInfoLayer;

@end
