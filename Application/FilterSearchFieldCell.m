#import "FilterSearchFieldCell.h"


@implementation FilterSearchFieldCell

- (void) endEditing:(NSText*)textObj
{
    [applicationController removeToolTipWindow];
    [super endEditing:textObj];
}

- (void)editWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject event:(NSEvent *)theEvent
{
    [applicationController showSearchTooltip];
    [super editWithFrame:aRect inView:controlView editor:textObj delegate:anObject event:theEvent];
}

- (void)selectWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject start:(NSInteger)selStart length:(NSInteger)selLength
{
    [applicationController showSearchTooltip];
    [super selectWithFrame:aRect inView:controlView editor:textObj delegate:anObject start:selStart length:selLength];
}

@end
