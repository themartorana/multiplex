#import <Cocoa/Cocoa.h>
#import "NSSet+IndyHallLabs.h"


@implementation NSSet (IndyHallLabs)

+ (BOOL) isSelectorExcludedFromWebScript:(SEL)selector {
    return NO;
}

@end

