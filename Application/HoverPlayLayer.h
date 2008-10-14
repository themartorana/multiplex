//
//  HoverPlayLayer.h
//  Multiplex
//
//  Created by David Martorana on 10/14/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

@class PlayButtonLayer;
@class Movie;

@interface HoverPlayLayer : CALayer {
    CALayer* surroundingLayer;
    CALayer* orangeBoxLayer;
    PlayButtonLayer* playButtonLayer; 
    
    CATextLayer* titleLayer;
    CATextLayer* runningTimeLayer;
    CATextLayer* ratingsLayer;
    CATextLayer* starsLayer;
    
    Movie* hoveredMovie;
    
    BOOL isInAlternatePosition;
}

@property (retain) Movie* hoveredMovie;
//@property BOOL isInAlternatePosition;

- (void) setUpLayerLayout;
- (void) putLayersIntoDefaultPosition;
- (void) putLayersIntoAlternatePosition;

@end
