#import <Cocoa/Cocoa.h>

@interface NSDictionary (KeyPaths)
+ (id) dictionaryWithExpandedKeyPathsAndObjects:(NSDictionary*)keyPathsAndObjects;
- (id) flattenToKeyPathsAndObjects;
@end

