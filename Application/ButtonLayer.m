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

@end
