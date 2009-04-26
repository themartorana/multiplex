#import "NSColor+IndyHallLabs.h"

@implementation NSColor (IndyHallLabs)

- (CGColorRef) colorAsCGColorRef
{
    CGColorSpaceRef colorSpace = [[self colorSpace] CGColorSpace];
    NSInteger componentCount = [self numberOfComponents];
    CGFloat *components = (CGFloat *)calloc(componentCount, sizeof(CGFloat));
    [self getComponents:components];
    CGColorRef color = CGColorCreate(colorSpace, components);
    free((void*)components);
    return color;
}

+ (NSColor*) colorWithRGBIn0To255ValuesForRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue alpha:(CGFloat)alpha;
{
    NSAssert(0 <= red <= 255, @"Red value must be between 0 and 255");
    NSAssert(0 <= blue <= 255, @"Blue value must be between 0 and 255");
    NSAssert(0 <= green <= 255, @"Green value must be between 0 and 255");
    NSAssert(0 <= alpha <= 255, @"Alpha value must be between 0 and 255");
    
    return [NSColor colorWithDeviceRed:red/255.0 
                                     green:green/255.0 
                                      blue:blue/255.0
                                 alpha:alpha/255.0];
}

@end
