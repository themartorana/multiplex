#import <Cocoa/Cocoa.h>

@protocol DrawerViewControllerProtocol <NSObject>

- (void) takeControl;
- (void) relinquishControl;

@end
