#import "Toolkit.h"

@implementation NSString (IndyHallLabs)

+ (id) stringWithUUID
{
    CFUUIDRef uuidRef = CFUUIDCreate(kCFAllocatorDefault);
    NSString* UUID = (NSString*)CFUUIDCreateString(kCFAllocatorDefault, uuidRef);
    CFRelease(uuidRef);
    return [UUID autorelease];
}

- (NSString*) urlEncodedString
{
	NSString* encodedValue = (NSString*)CFURLCreateStringByAddingPercentEscapes(
							    NULL,
								(CFStringRef)self,
								NULL,
								(CFStringRef)@"!*'\"();:@&=+$,/?%#[]% ",
								kCFStringEncodingUTF8
	);

	return [encodedValue autorelease];
}

@end
