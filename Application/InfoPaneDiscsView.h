//
//  InfoPaneDisksView.h
//  Multiplex
//
//  Created by David Martorana on 10/8/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Movie;

@interface InfoPaneDiscsView : NSView {
    Movie* selectedMovie;
    
    CALayer* scrollingLayer;
    CALayer* discsHostingLayer;
}

@property (retain) Movie* selectedMovie;

- (void) setUpDiskLayers;

@end
