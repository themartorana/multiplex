#import "DragDropTargetView.h"
#import <Toolkit/Toolkit.h>

@implementation DragDropTargetView
@synthesize delegate;

- (void) setDelegate:(id)_delegate
{
    if (delegate != _delegate) {
        if (delegate) {
            [self unregisterDraggedTypes];
        }
        [delegate release];
        delegate = [_delegate retain];
        if (delegate && [delegate respondsToSelector:@selector(registeredDragTypesForDragDropTargetView:)]) {
            [self registerForDraggedTypes:[delegate registeredDragTypesForDragDropTargetView:self]];
        }
    }
}

- (void) drawRect:(NSRect)rect
{
	if (_highlighted) {
		[NSGraphicsContext saveGraphicsState];
		[[NSGraphicsContext currentContext] setShouldAntialias:YES];

		NSRect bounds = [self bounds];
		[[NSColor colorWithCalibratedWhite:0.9 alpha:1.0] set];
		NSBezierPath* path = [NSBezierPath bezierPathWithRoundedRect:NSInsetRect(bounds, 3, 3) cornerRadius:10.0 inCorners:kIHTopLeftCorner | kIHBottomLeftCorner | kIHTopRightCorner | kIHBottomRightCorner];
		float lineDash[2];
		lineDash[0] = 20.0;
		lineDash[1] = 5.0;
		[path setLineDash:lineDash count:2 phase:_phase];
		[path setFlatness:0.0];    
		[path setLineWidth:2.5];
		[path stroke];

		[NSGraphicsContext restoreGraphicsState];
	}
}

- (void) _updatePhase
{
	_phase = (_phase + 3) % 25;
	[self setNeedsDisplay:YES];
}

- (void) _beginHighlightAnimation
{
	_highlighted = YES;
	_timer = [[NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(_updatePhase) userInfo:nil repeats:YES] retain];
	[self setNeedsDisplay:YES];
}

- (void) _endHighlightAnimation
{
	_highlighted = NO;
	[_timer invalidate];
	[_timer release];
	_timer = nil;
	[self setNeedsDisplay:YES];
}

- (NSDragOperation) draggingEntered:(id <NSDraggingInfo>)sender 
{
    NSPasteboard *pb = [sender draggingPasteboard];
    BOOL allowDrag = NO;
    if ([delegate respondsToSelector:@selector(dragDropTargetView:allowDragForPasteboard:)]) {
        allowDrag = [delegate dragDropTargetView:self allowDragForPasteboard:pb];
    }
    if (allowDrag) {
        [self _beginHighlightAnimation];
        return NSDragOperationCopy;
    } else {
        return NSDragOperationNone;
    }
}

- (void) draggingExited:(id <NSDraggingInfo>)sender
{
	[self _endHighlightAnimation];
}

- (BOOL) performDragOperation:(id <NSDraggingInfo>)sender 
{
	[self _endHighlightAnimation];

    NSPasteboard *pb = [sender draggingPasteboard];
    BOOL acceptDragOperation = NO;
    if ([delegate respondsToSelector:@selector(dragDropTargetView:acceptDragForPasteboard:)]) {
        acceptDragOperation = [delegate dragDropTargetView:self acceptDragForPasteboard:pb];
    }
    return acceptDragOperation;
}

@end
