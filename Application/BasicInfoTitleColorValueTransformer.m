#import "BasicInfoTitleColorValueTransformer.h"

@implementation BasicInfoTitleColorValueTransformer

+ (Class)transformedValueClass { return [NSObject class]; }

+ (BOOL)allowsReverseTransformation { return NO; }

- (id) transformedValue:(id)value {
    CGColorRef color = nil;
    if ([(NSNumber*)value boolValue]) {
        color = CGColorCreateGenericRGB(1.0, 1.0, 1.0, 1.0);
    }
    else {
        color = CGColorCreateGenericRGB(253.0/255.0, 187.0/255.0, 99.0/255.0, 1.0);        
    }
    
    if (color) {
        [NSAutoreleasePool addObject:(id)color];
    }
    return (id)color;
}

@end
