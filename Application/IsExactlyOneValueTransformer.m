#import "IsExactlyOneValueTransformer.h"

@implementation IsExactlyOneValueTransformer

+ (Class) transformedValueClass { return [NSNumber class]; }

+ (BOOL) allowsReverseTransformation { return NO; }

- (NSNumber*) transformedValue:(NSNumber*)value 
{
    if (value && [value intValue] == 1) {
        return (id)kCFBooleanTrue;
    } else {
        return (id)kCFBooleanFalse;
    }
}

@end
