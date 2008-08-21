#import <Foundation/Foundation.h>

@interface NSArray (JSONKit)

+ (id) arrayWithJSON:(NSString*)json;

@end

@interface NSData (JSONKit)

+ (id) dataWithObjectAsJSON:(id)object;

@end

@interface NSDictionary (JSONKit)

+ (id) dictionaryWithJSON:(NSString*)json;

@end

@interface NSObject (JSONKit)

+ (id) objectWithJSON:(NSString*)json;

@end

@interface NSString (JSONKit)

+ (id) stringWithObjectAsJSON:(id)object;

@end