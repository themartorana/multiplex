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
    
    /* Layers for basic info */
    CALayer* basicInfoLayer;
    CALayer* surroundingLayer;
    CALayer* titleHostingLayer;
    CATextLayer* titleLayer;
    CATextLayer* selectedTextLayer;
    CALayer* secondaryInfoLayer;
    CATextLayer* numDiscsLayer;
    CATextLayer* ratingLayer;
    CALayer* playButtonLayer;
    CALayer* infoButtonLayer;
    
    NSTrackingArea* mouseTrackingArea;
    NSString* numDiscsString;
    NSString* ratingString;
    NSString* movieTitleString;
}

@property (retain) NSArray* selectedMovies;
@property (retain) Movie* hoveredMovie;
@property (readonly) NSString* numDiscsString;
@property (readonly) NSString* ratingString;
@property (readonly) NSString* movieTitleString;

- (void) setUpBasicInfoLayer;

@end
