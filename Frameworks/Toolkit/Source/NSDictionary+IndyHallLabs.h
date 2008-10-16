#import <Cocoa/Cocoa.h>

@interface NSDictionary (IndyHallLabs)
+ (id) dictionaryWithExpandedKeyPathsAndObjects:(NSDictionary*)keyPathsAndObjects;
- (id) flattenToKeyPathsAndObjects;
@end

