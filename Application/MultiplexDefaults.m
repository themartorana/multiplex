#import "MultiplexDefaults.h"


@implementation MultiplexDefaults

+ (NSUserDefaults*) standardUserDefaults
{
    return [NSUserDefaults standardUserDefaults];
}

+ (NSTimeInterval) doubleClickDelayTimeInterval
{
    // TODO: Figure out how to get this dynamically
    return 0.5;
}

@end
