#import "BlurredBackgroundView.h"
#import <QuartzCore/QuartzCore.h>

@implementation BlurredBackgroundView

- (BOOL) isOpaque
{
    return YES;
}

- (BOOL) acceptsFirstMouse:(NSEvent*)theEvent
{
    return YES;
}

- (void) viewDidUnhide
{
    CIFilter* blurFilter = [CIFilter filterWithName:@"CIGaussianBlur"];
    [blurFilter setDefaults];
    [blurFilter setValue:[NSNumber numberWithInt:2.0] forKey:@"inputRadius"];
    [self setBackgroundFilters:[NSArray arrayWithObject:blurFilter]];
}

- (void) viewDidHide
{
    [self setBackgroundFilters:nil];
}

- (void) drawRect:(NSRect)rect
{
    [[[NSColor blackColor] colorWithAlphaComponent:0.4] set];
    NSRectFill(self.frame);
}

- (BOOL) mouseDownCanMoveWindow {
    return NO;
}

@end
