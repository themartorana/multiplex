#import "VerticalScroller.h"

@implementation VerticalScroller

- (id) initWithFrame:(NSRect)frame 
{
    if (self = [super initWithFrame:frame]) {
        [self setArrowsPosition:NSScrollerArrowsNone];
    }
    return self;
}

- (void) drawKnob
{
	NSRect rect = [self rectForPart:NSScrollerKnob];
    
    NSBezierPath* path = [NSBezierPath bezierPath];
}

- (void) drawKnobSlotInRect:(NSRect)rect highlight:(BOOL)highlight
{
	if ([[super window] isMainWindow] && [[super window] isKeyWindow]) {
	} else {
	}

    CGFloat midX = NSMidX(rect);
    NSBezierPath* path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(midX, NSMinY(rect))];
    [path lineToPoint:NSMakePoint(midX, NSMaxY(rect))];
    
    [[NSColor whiteColor] set];
    [path stroke];
}

- (void) drawRect:(NSRect)rect
{
	[self drawKnobSlotInRect:[self rectForPart:NSScrollerKnobSlot] highlight:NO];
	[self drawKnob];
}

@end
