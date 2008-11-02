#import "NSNumberToStringValueTransformer.h"


@implementation NSNumberToStringValueTransformer

+ (Class)transformedValueClass { return [NSAttributedString class]; }

+ (BOOL)allowsReverseTransformation { return NO; }

- (NSString*) transformedValue:(NSNumber*)value {
    if (value) {
        NSString* str = [value stringValue];
        return str;
    }
    else {
        return @"";
    }
}

- (NSNumber*) reverseTransformedValue:(NSString*)value {
    if (value) {
        @try {
            NSNumber* num = [NSNumber numberWithInt:[value intValue]];
            return num;
        }
        @catch (NSException * e) {
            NSLog(@"Cannot transform value to NSNumber: %@", e);
            return [NSNumber numberWithInt:-1];
        }
    }
    else {
        return [NSNumber numberWithInt:-1];
    }
    
    // Compiler was bitching about reaching the end of a non-void function,
    // even though that's technically impossible.
    return [NSNumber numberWithInt:-1];
}

@end
