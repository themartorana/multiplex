//
//  InfoPaneDisksView.h
//  Multiplex
//
//  Created by David Martorana on 10/8/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Movie;
@class DiscPlayLayer;
@class PlayButtonLayer;

@interface InfoPaneDiscsView : NSView {
    Movie* selectedMovie;
    
    CALayer* viewLayer;
    CALayer* scrollingLayer;
    CALayer* discsHostingLayer;
    CALayer* pageNumbersLayer;
    
    NSTrackingArea* mouseTrackingArea;
    
    DiscPlayLayer* hoveredLayer;
    PlayButtonLayer* playButtonDownLayer;
}

@property (retain) Movie* selectedMovie;

- (void) setUpDiscLayers;
- (void) unhoverHoveredLayer;

@end
