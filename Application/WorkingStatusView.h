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
