#import "MovieDetailTokenFieldValueTransformer.h"

#import <JSONKit/JSONKit.h>

@implementation MovieDetailTokenFieldValueTransformer

+ (Class)transformedValueClass { return [NSArray class]; }

+ (BOOL)allowsReverseTransformation { return YES; }

- (NSArray*) transformedValue:(NSString*)value {
    if (value) {
        NSArray* arr;
        arr = [NSArray arrayWithJSON:value];
        return arr;
    }
    else {
        return nil;
    }
}

- (NSString*) reverseTransformedValue:(NSArray*)value
{
    if (value) {
        return [NSString stringWithObjectAsJSON:value];
    }
    else {
        return nil;
    }
}

@end
