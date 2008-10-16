#import <Cocoa/Cocoa.h>

@interface NSColor (IndyHallLabs)

+ (NSColor*) colorWithRGBIn0To255ValuesForRed:(int)red green:(int)green blue:(int)blue alpha:(int)alpha;

- (CGColorRef) colorAsCGColorRef;

@end
