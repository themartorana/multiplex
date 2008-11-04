#import "NSValueTransformer+IndyHallLabs.h"

@implementation NSValueTransformer (IndHallLabs)

+ (void) registerYourself
{
    NSString* name = NSStringFromClass(self);
    id instance = [[[self alloc] init] autorelease];
#ifdef DEBUG
    NSLog(@"Registering Value Transformer: %@ (%@)", name, instance);
#endif
    if ([name hasSuffix:@"ValueTransformer"]) {
        name = [name substringToIndex:[name length] - 16];
    }
    [NSValueTransformer setValueTransformer:instance forName:name];
}

@end
