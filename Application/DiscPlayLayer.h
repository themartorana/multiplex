//
//  untitled.h
//  Multiplex
//
//  Created by David Martorana on 10/8/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

@class PlayButtonLayer;
@class Disc;

@interface DiscPlayLayer : CALayer {

    PlayButtonLayer* playButtonLayer;
    CATextLayer* discNumberTitle;
    CATextLayer* descriptionLayer;
    
    NSTrackingArea* trackingArea;
    
    Disc* _disc;
}

@end
