#import "Toolkit.h"

@implementation NSString (IndyHallLabs)

+ (id) stringWithUUID
{
    CFUUIDRef uuidRef = CFUUIDCreate(kCFAllocatorDefault);
    NSString* UUID = (NSString*)CFUUIDCreateString(kCFAllocatorDefault, uuidRef);
    CFRelease(uuidRef);
    return [UUID autorelease];
}

@end
