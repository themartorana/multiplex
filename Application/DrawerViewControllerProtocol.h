#import <Cocoa/Cocoa.h>

@protocol DrawerViewControllerProtocol <NSObject>

- (void) takeControl;
- (BOOL) relinquishControl;

@end
