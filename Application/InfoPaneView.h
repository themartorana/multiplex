//
//  InfoPaneView.h
//  Multiplex
//
//  Created by David Martorana on 10/6/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

@class PlayButtonLayer;
@class InfoButtonLayer;
@class CloseButtonLayer;
@class GreyButtonLayer;

@interface InfoPaneView : NSView {
    PlayButtonLayer* playButtonLayer;
    InfoButtonLayer* infoButtonLayer;
    CloseButtonLayer* closeButtonLayer;
    GreyButtonLayer* greyPlayButtonLayer;
    
    NSTrackingArea* mouseTrackingArea;
    NSTrackingArea* playButtonTrackingArea;
}

@end
