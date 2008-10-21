#import "DrawerView.h"
#import "MultiplexColorFactory.h"
#import <QuartzCore/QuartzCore.h>

@implementation DrawerView
@synthesize isOpen;
@synthesize contentView;

- (void) awakeFromNib
{
    minHeight = [self frame].size.height;
    
    CALayer* root = [self layer];
    [root setLayoutManager:[CAConstraintLayoutManager layoutManager]];

    CALayer* solidLayer = [CALayer layer];
    solidLayer.backgroundColor = [MultiplexColorFactory drawerBackgroundBaseColor];
    solidLayer.constraints = [NSArray arrayWithObjects:
        [CAConstraint constraintWithAttribute:kCAConstraintMinX relativeTo:@"superlayer" attribute:kCAConstraintMinX],
        [CAConstraint constraintWithAttribute:kCAConstraintMinY relativeTo:@"superlayer" attribute:kCAConstraintMinY],
        [CAConstraint constraintWithAttribute:kCAConstraintMaxX relativeTo:@"superlayer" attribute:kCAConstraintMaxX],
        [CAConstraint constraintWithAttribute:kCAConstraintMaxY relativeTo:@"superlayer" attribute:kCAConstraintMaxY scale:1.0 offset:-50],
        nil
    ];
    [root addSublayer:solidLayer];
    
    CALayer* patternLayer = [CALayer layer];
    patternLayer.backgroundColor = [MultiplexColorFactory drawerBackgroundPattern];
    patternLayer.constraints = [NSArray arrayWithObjects:
        [CAConstraint constraintWithAttribute:kCAConstraintMinX relativeTo:@"superlayer" attribute:kCAConstraintMinX],
        [CAConstraint constraintWithAttribute:kCAConstraintMinY relativeTo:@"superlayer" attribute:kCAConstraintMinY],
        [CAConstraint constraintWithAttribute:kCAConstraintMaxX relativeTo:@"superlayer" attribute:kCAConstraintMaxX],
        [CAConstraint constraintWithAttribute:kCAConstraintMaxY relativeTo:@"superlayer" attribute:kCAConstraintMaxY scale:1.0 offset:-50],
        nil
    ];
    [root addSublayer:patternLayer];
}

- (void) setContentView:(NSView*)_contentView
{
    if (contentView != _contentView) {
        [contentView release];
        contentView = [_contentView retain];
    }
}

- (void) openDrawer
{
    if (!isOpen) {
        NSRect frame = [self frame];
        NSRect viewFrame = [contentView frame];
        NSRect superViewFrame = [self.superview frame];
        NSRect upperViewFrame = [upperView frame];
        
        NSRect newFrame = NSMakeRect(0, -viewFrame.size.height, frame.size.width, viewFrame.size.height + minHeight);
        NSRect newViewFrame = NSMakeRect(round((frame.size.width / 2.0) - (viewFrame.size.width / 2.0)), 0, viewFrame.size.width, viewFrame.size.height);
        NSRect newUpperViewFrame = NSMakeRect(upperViewFrame.origin.x, viewFrame.size.height + minHeight, upperViewFrame.size.width, superViewFrame.size.height - (viewFrame.size.height + minHeight));
        
        [self setFrame:newFrame];
        [contentView setFrame:newViewFrame];
        [self addSubview:contentView];

        [NSAnimationContext beginGrouping];
        if ([[NSApp currentEvent] modifierFlags] & NSShiftKeyMask) {
            [[NSAnimationContext currentContext] setDuration:2.0];
        }
        [button setFrameCenterRotation:45.0];
        [[upperView animator] setFrame:newUpperViewFrame];
        [[self animator] setFrame:NSOffsetRect(newFrame, 0, viewFrame.size.height)];
        [NSAnimationContext endGrouping];
        isOpen = YES;
    }
}

- (void) closeDrawer
{
    if (isOpen) {
        NSRect frame = [self frame];
        NSRect viewFrame = [contentView frame];
        NSRect superViewFrame = [self.superview frame];
        NSRect upperViewFrame = [upperView frame];
        NSRect newUpperViewFrame = NSMakeRect(upperViewFrame.origin.x, minHeight, upperViewFrame.size.width, superViewFrame.size.height - minHeight);

        [NSAnimationContext beginGrouping];
        if ([[NSApp currentEvent] modifierFlags] & NSShiftKeyMask) {
            [[NSAnimationContext currentContext] setDuration:2.0];
        }
        [button setFrameCenterRotation:0.0];
        [[upperView animator] setFrame:newUpperViewFrame];
        [[self animator] setFrame:NSOffsetRect(frame, 0, -viewFrame.size.height)];
        [NSAnimationContext endGrouping];
        [contentView removeFromSuperview];
        isOpen = NO;
    }
}

- (IBAction) toggle:(id)sender
{
    if (isOpen) {
        [self closeDrawer];
    } else {
        [self openDrawer];
    }
}

@end
