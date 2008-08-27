#import "NSString+UUID.h"

@implementation NSString (UUID)

+ (id) stringWithUUID
{
    CFUUIDRef uuidRef = CFUUIDCreate(kCFAllocatorDefault);
    NSString* UUID = (NSString*)CFUUIDCreateString(kCFAllocatorDefault, uuidRef);
    CFRelease(uuidRef);
    return [UUID autorelease];
}

@end
