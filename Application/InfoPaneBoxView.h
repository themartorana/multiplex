//
//  InfoPaneBoxView.h
//  Multiplex
//
//  Created by David Martorana on 10/8/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Movie;
@class InfoPaneFormController;

@interface InfoPaneBoxView : NSView {
    Movie* selectedMovie;
    IBOutlet InfoPaneFormController* controller;
}

@property (retain) Movie* selectedMovie;

@end
