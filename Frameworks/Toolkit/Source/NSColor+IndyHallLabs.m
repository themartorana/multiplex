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

+ (NSColor*) colorWithRGBIn0To255ValuesForRed:(int)red green:(int)green blue:(int)blue alpha:(int)alpha;
{
    NSAssert(0 <= red <= 255, @"Red value must be between 0 and 255");
    NSAssert(0 <= blue <= 255, @"Blue value must be between 0 and 255");
    NSAssert(0 <= green <= 255, @"Green value must be between 0 and 255");
    NSAssert(0 <= alpha <= 255, @"Alpha value must be between 0 and 255");
    
    return [NSColor colorWithDeviceRed:((float)red)/255.0 
                                     green:((float)green)/255.0 
                                      blue:((float)blue)/255 
                                     alpha:((float)alpha)/255];
}

@end
