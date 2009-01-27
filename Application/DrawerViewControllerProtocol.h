#import <Cocoa/Cocoa.h>
#import "ExecuteTokenProtocol.h"

@class ApplicationController;
@class DrawerView;

@protocol DrawerViewControllerProtocol <NSObject>

- (id) initWithApplicationController:(ApplicationController*)ac drawerView:(DrawerView*)dv;

- (void) takeControl;
- (void) pleaseRelinquishControlAndApprove:(id<ExecuteTokenProtocol>)executeToken;

@end
