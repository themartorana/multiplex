#import <Cocoa/Cocoa.h>

@interface NSBundle (IndyHallLabs)

+ (NSBundle*) bundleWithIdentifierStringFromLS:(NSString*)identifier;

- (NSString*) version;
- (NSString*) shortVersion;

@end
