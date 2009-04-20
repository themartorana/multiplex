#import <Cocoa/Cocoa.h>
#import "ApplicationController.h"

@interface FilterSearchFieldCell : NSSearchFieldCell {
    IBOutlet ApplicationController* applicationController;
}

@end
