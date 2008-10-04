//
//  WorkingStatusView.h
//  Multiplex
//
//  Created by David Martorana on 10/1/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "IndeterminateProgressIndicatorLayer.h"

@interface WorkingStatusView : NSView {
    NSMutableDictionary* activityDictionary;
    
    IndeterminateProgressIndicatorLayer* _spinnerLayer;
}

- (void) activityStarted:(NSNotification*)notification;
- (void) activityTerminated:(NSNotification*)notification;
- (void) activityPercentCompleteUpdated:(NSNotification*)notification;

@end
