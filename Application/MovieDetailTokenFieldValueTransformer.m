#import "MovieDetailTokenFieldValueTransformer.h"


@implementation MovieDetailTokenFieldValueTransformer

+ (Class)transformedValueClass { return [NSArray class]; }

+ (BOOL)allowsReverseTransformation { return YES; }

- (NSArray*) transformedValue:(NSString*)value {
    if (value) {
        NSArray* arr = [value componentsSeparatedByString:@","];
        for (NSString* str in arr) {
            str = [str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        }
        
        return arr;
    }
    else {
        return nil;
    }
}

- (NSString*) reverseTransformedValue:(NSArray*)value
{
    if (value) {
        NSMutableString* genreString = [NSMutableString string];
        
        for (NSString* str in value) {
            if ([genreString length] > 0) {
                [genreString appendString:@","];
            }
            [genreString appendString:str];
        }
        
        return [NSString stringWithString:genreString];
    }
    else {
        return nil;
    }
}

@end
