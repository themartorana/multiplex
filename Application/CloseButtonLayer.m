#import "CloseButtonLayer.h"
#import "NSImage+Mothership.h"

@implementation CloseButtonLayer

@synthesize isMouseDown;

- (CloseButtonLayer*) init
{
    if (self = [super init]) {
        // Load our play button image
        closeButtonImage = [NSImage closeButton];
        closeButtonImageDown = [NSImage closeButtonDown];
    }
    
    [self setNeedsDisplay];
    return self;
}

- (void) dealloc
{
    CGImageRelease(closeButtonImage);
    CGImageRelease(closeButtonImageDown);
    [super dealloc];
}

- (void) setIsMouseDown:(BOOL)down
{
    isMouseDown = down;
    [self setNeedsDisplay];
}

- (void) drawInContext:(CGContextRef)c
{
    if (!isMouseDown)
        CGContextDrawImage(c, self.bounds, closeButtonImage);
    else
        CGContextDrawImage(c, self.bounds, closeButtonImageDown);
}


@end
