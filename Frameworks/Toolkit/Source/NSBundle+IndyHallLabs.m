#import "NSBundle+IndyHallLabs.h"

@implementation NSBundle (IndyHallLabs)

- (NSString*) version
{
    return [[self infoDictionary] objectForKey:@"CFBundleVersion"];
}

@end