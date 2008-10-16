#import "NSDictionary+IndyHallLabs.h"

@implementation NSDictionary (IndyHallLabs)

+ (id) dictionaryWithExpandedKeyPathsAndObjects:(NSDictionary*)keyPathsAndObjects
{
    // TODO: Rewrite using CoreFoundation.
    NSMutableDictionary* result = [NSMutableDictionary dictionary];
    for (NSString* keyPath in keyPathsAndObjects) {
        id theObject = [keyPathsAndObjects objectForKey:keyPath];
        NSMutableDictionary* dict = result;
        NSArray* segments = [keyPath componentsSeparatedByString:@"."];
        int count = [segments count];
        if (count > 1) {
            keyPath = [segments lastObject];
            for (NSString* segment in [segments subarrayWithRange:NSMakeRange(0, count - 1)]) {
                NSMutableDictionary* o = [dict objectForKey:segment];
                if (!o) {
                    [dict setObject:o = [NSMutableDictionary dictionary] forKey:segment];
                }
                dict = o;
            }
        }
        [dict setObject:theObject forKey:keyPath];
    }
    return result;
}

static void addKeysAndValuesWithPrefix(NSMutableDictionary* target, NSDictionary* source, NSString* prefix)
{
    // TODO: Rewrite using CoreFoundation.
    for (NSString* key in source) {
        NSString* newKey = [prefix stringByAppendingString:key];
        id object = [source objectForKey:key];
        if ([object isKindOfClass:[NSDictionary class]]) {
            addKeysAndValuesWithPrefix(target, object, [newKey stringByAppendingString:@"."]);
        } else {
            [target setObject:object forKey:newKey];
        }
    }
}

- (id) flattenToKeyPathsAndObjects
{
    // TODO: Rewrite using CoreFoundation.
    NSMutableDictionary* result = [NSMutableDictionary dictionary];
    addKeysAndValuesWithPrefix(result, self, @"");
    return result;
}

@end
