#import <Cocoa/Cocoa.h>

@interface NSColor (IndyHallLabs)

+ (NSColor*) colorWithRGBIn0To255ValuesForRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue alpha:(CGFloat)alpha;
+ (NSColor*) colorWithCGColor:(CGColorRef)color;

- (CGColorRef) colorAsCGColorRef;

@end
