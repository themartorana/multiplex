#import "CALayer+Mothership.h"

@implementation CALayer (Mothership)

- (void) removeAllSublayers
{
    if (![self sublayers] || [[self sublayers] count] <= 0) {
        return;
    }
    
    NSMutableArray* tmpArray = [NSMutableArray array];
    for (CALayer* layer in [self sublayers]) {
        [tmpArray addObject:layer];
    }
    
    for (id obj in tmpArray) {
        if ([obj isKindOfClass:[CALayer class]]) {
            [(CALayer*)obj removeFromSuperlayer];
        }
    }
    
    [tmpArray removeAllObjects];
}

@end
