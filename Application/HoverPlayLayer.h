//
//  HoverPlayLayer.h
//  Multiplex
//
//  Created by David Martorana on 10/14/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

@class ButtonLayer;
@class Movie;

@interface HoverPlayLayer : CALayer {
    CALayer* surroundingLayer;
    CALayer* orangeBoxLayer;
    ButtonLayer* playButtonLayer; 
    
    CATextLayer* titleLayer;
    CATextLayer* additionalInfoLayer;
    
    Movie* hoveredMovie;
    
    BOOL isInAlternatePosition;
    BOOL isMouseDown;
}

@property (retain) Movie* hoveredMovie;
@property BOOL isMouseDown;

@end
