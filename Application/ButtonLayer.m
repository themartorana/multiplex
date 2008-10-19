#import "ButtonLayer.h"
#import <QuartzCore/QuartzCore.h>

@implementation ButtonLayer

@synthesize isMouseDown;
@synthesize upState;
@synthesize downState;

+ (id) buttonLayerWithUpState:(CGImageRef)upState downState:(CGImageRef)downState
{
    ButtonLayer* layer = [self layer];
    layer.upState = upState;
    layer.downState = downState;
    return layer;
}

- (void) dealloc
{
    if (upState) {
        CGImageRelease(upState);
    }
    if (downState) {
        CGImageRelease(downState);
    }
    [super dealloc];
}

- (void) setUpState:(CGImageRef)_upState
{
    if (upState != _upState) {
        if (upState) {
            CGImageRelease(upState);
        }
        if (_upState) {
            CGImageRetain(_upState);
        }
        upState = _upState;
        [self setNeedsDisplay];
    }
}

- (void) setDownState:(CGImageRef)_downState
{
    if (downState != _downState) {
        if (downState) {
            CGImageRelease(downState);
        }
        if (_downState) {
            CGImageRetain(_downState);
        }
        downState = _downState;
        [self setNeedsDisplay];
    }
}

- (void) setIsMouseDown:(BOOL)down
{
    isMouseDown = down;
    [self setNeedsDisplay];
}

- (void) drawInContext:(CGContextRef)c
{
    if (!isMouseDown) {
        CGContextDrawImage(c, self.bounds, upState);
    } else {
        CGContextDrawImage(c, self.bounds, downState);
    }
}

- (CALayer*) hitTest:(CGPoint)point
{
    CALayer* layer = [super hitTest:point];
    if (!layer || layer != self) {
        return layer;
    }
    
    CGImageRef image = isMouseDown ? downState : upState;
    if (!image) {
        return self;
    }

    /*  Create 1x1 BitmapContext
     */
    UInt32 thePixel = 0;
    CGColorSpaceRef colorspace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
    CGContextRef bmpCtx = CGBitmapContextCreate(&thePixel, 1, 1, 8, 4, colorspace, kCGImageAlphaPremultipliedFirst);
    
    /*  Move it to "where"
     */
    CGRect frame = self.frame;
    CGContextTranslateCTM(bmpCtx, -(point.x - frame.origin.x), -(point.y - frame.origin.y));
    CGContextDrawImage(bmpCtx, CGRectMake(0, 0, frame.size.width, frame.size.height), image);
    
#if 0
    NSLog(@"%@: %08x", NSStringFromPoint(NSPointFromCGPoint(adjustedPoint)), thePixel);
#endif

    /*  Cleanup 
     */
    CGColorSpaceRelease(colorspace);
    CGContextRelease(bmpCtx);

    /*  Did we hit a pixel with a less-than completely opaque alpha-channel?
     */
    return ((thePixel & 0xFF) == 0xFF) ? self : nil;
}

@end
