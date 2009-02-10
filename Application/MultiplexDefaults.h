#import <Cocoa/Cocoa.h>


@interface MultiplexDefaults : NSObject {

}

+ (NSUserDefaults*) standardUserDefaults;
+ (NSTimeInterval) doubleClickDelayTimeInterval;

@end
