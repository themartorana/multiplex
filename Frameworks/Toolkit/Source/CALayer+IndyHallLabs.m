#import <Cocoa/Cocoa.h>
#import "Toolkit.h"

@implementation CALayer (IndyHallLabs)

+ (CALayer*) maskLayer
{
    CGRect r;
    r.origin = CGPointZero;
    r.size = CGSizeMake(100, 100);
    size_t bytesPerRow = 4 * r.size.width;
    void* bitmapData = malloc(bytesPerRow * r.size.height);
    CGContextRef context = CGBitmapContextCreate(
                                                 bitmapData, 
                                                 r.size.width,
                                                 r.size.height, 
                                                 8,  
                                                 bytesPerRow, 
                                                 CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB), 
                                                 kCGImageAlphaPremultipliedFirst
                                                 );
    NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithDeviceWhite:0.0 alpha:0.0] endingColor:[NSColor colorWithDeviceWhite:0.0 alpha:0.5]];
    NSGraphicsContext *nsContext = [NSGraphicsContext graphicsContextWithGraphicsPort:context flipped:NO];
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:nsContext];
    [[NSColor clearColor] set];
    NSRectFill(NSMakeRect(0, 0, r.size.width, r.size.height));
    [gradient drawInRect:NSMakeRect(0, r.size.height / 2, r.size.width, r.size.height) angle:90];
    [NSGraphicsContext restoreGraphicsState];
    CGImageRef image = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    free(bitmapData);
    [gradient release];
    
    CALayer* mask = [CALayer layer];
    [mask setAutoresizingMask:kCALayerHeightSizable | kCALayerWidthSizable];
    [mask setContents:(id)image];
    [mask setAnchorPoint:CGPointMake(0.0, 0.0)];
    [mask setTransform:CATransform3DMakeScale(1.0, -1.0, 1.0)];
    
    CGImageRelease(image);
    
    return mask;
}

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
