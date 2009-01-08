//
//  HoverInfoView.h
//  Multiplex
//
//  Created by David Martorana on 1/7/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Movie;
@class WebView;

@interface HoverInfoView : NSView {
    Movie* movie;
    IBOutlet WebView* webView;
    BOOL inFlipPosition;
}

@property (retain) Movie* movie;
@property BOOL inFlipPosition;

@end
