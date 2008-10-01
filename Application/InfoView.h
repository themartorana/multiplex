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
#import "PlayButtonLayer.h"

@interface InfoView : NSView {
    NSArray* selectedMovies;
    Movie* hoveredMovie;
    
    /* Layers for basic info */
    CALayer* basicInfoLayer;
    CALayer* surroundingLayer;
    CALayer* titleHostingLayer;
    CALayer* secondaryInfoLayer;
    CALayer* infoButtonLayer;
        
    CATextLayer* titleLayer;
    CATextLayer* numDiscsLayer;
    CATextLayer* ratingLayer;
    
    PlayButtonLayer* playButtonLayer;
    
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
