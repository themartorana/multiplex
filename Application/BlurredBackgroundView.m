#import "BlurredBackgroundView.h"
#import <QuartzCore/QuartzCore.h>

@implementation BlurredBackgroundView

- (BOOL) isOpaque
{
    return YES;
}

- (void) drawRect:(NSRect)rect
{
    [[[NSColor blackColor] colorWithAlphaComponent:0.4] set];
    NSRectFill(self.frame);
}

@end
