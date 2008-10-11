#import "BigPlayButtonView.h"
#import "PlayButtonLayer.h"

#import <QuartzCore/QuartzCore.h>

@implementation BigPlayButtonView

- (void) awakeFromNib
{
    [self setWantsLayer:YES];
    
    playButtonLayer = [PlayButtonLayer layer];
    playButtonLayer.anchorPoint = CGPointZero;
    playButtonLayer.frame = NSRectToCGRect([self bounds]);
    [[self layer] addSublayer:playButtonLayer];
}

- (void)mouseDown:(NSEvent *)theEvent
{
    playButtonLayer.isMouseDown = YES;
}

- (void)mouseUp:(NSEvent *)theEvent
{
    playButtonLayer.isMouseDown = NO;
    
    CGPoint p = NSPointToCGPoint([self convertPoint:[theEvent locationInWindow] fromView:nil]);
    CALayer* layer = [playButtonLayer hitTest:p];
    
    if (layer && layer == playButtonLayer) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"MultiplexPlayButtonClicked" object:nil];
    }
}


@end
