// TODO: Add removal of the box images!

#import "NSMutableDictionary+Mothership.h"

static NSMutableDictionary* boxImages;

@implementation NSMutableDictionary (Mothership)

+ (void) addBoxImage:(CGImageRef)image forKey:(id)key;
{
    if (!boxImages) {
        boxImages = [[NSMutableDictionary dictionary] retain];
        NSLog(@"Created boxes dict");
    }
    
    if (image) {
        [boxImages setObject:(id)image forKey:key];        
    }
}

+ (CGImageRef) boxImageForKey:(id)key
{
    return (CGImageRef)[boxImages valueForKey:key];
}

@end
