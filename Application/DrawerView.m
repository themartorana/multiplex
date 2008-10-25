#import "DrawerView.h"
#import "MultiplexColorFactory.h"
#import "ApplicationResources.h"
#import <QuartzCore/QuartzCore.h>

@implementation DrawerView
@synthesize isOpen;
@synthesize contentView;

- (void) awakeFromNib
{
    minHeight = [self frame].size.height;
    
    CALayer* root = [self layer];
    [root setLayoutManager:[CAConstraintLayoutManager layoutManager]];

    CALayer* backgroundLayer = [CALayer layer];
    backgroundLayer.contents = (id)[ApplicationResources textureForDrawerBackground];
    backgroundLayer.constraints = [NSArray arrayWithObjects:
        [CAConstraint constraintWithAttribute:kCAConstraintMinX relativeTo:@"superlayer" attribute:kCAConstraintMinX],
        [CAConstraint constraintWithAttribute:kCAConstraintMinY relativeTo:@"superlayer" attribute:kCAConstraintMinY],
        [CAConstraint constraintWithAttribute:kCAConstraintMaxX relativeTo:@"superlayer" attribute:kCAConstraintMaxX],
        [CAConstraint constraintWithAttribute:kCAConstraintMaxY relativeTo:@"superlayer" attribute:kCAConstraintMaxY scale:1.0 offset:-50],
        nil
    ];
    [root addSublayer:backgroundLayer];
    
    CALayer* patternLayer = [CALayer layer];
    patternLayer.backgroundColor = [MultiplexColorFactory drawerBackgroundPattern];
    patternLayer.constraints = [NSArray arrayWithObjects:
        [CAConstraint constraintWithAttribute:kCAConstraintMinX relativeTo:@"superlayer" attribute:kCAConstraintMinX],
        [CAConstraint constraintWithAttribute:kCAConstraintMinY relativeTo:@"superlayer" attribute:kCAConstraintMinY],
        [CAConstraint constraintWithAttribute:kCAConstraintMaxX relativeTo:@"superlayer" attribute:kCAConstraintMaxX],
        [CAConstraint constraintWithAttribute:kCAConstraintMaxY relativeTo:@"superlayer" attribute:kCAConstraintMaxY scale:1.0 offset:-52],
        nil
    ];
    [root addSublayer:patternLayer];

    CALayer* topEdgeLayer = [CALayer layer];
    CGImageRef textureForDrawerTopEdge = [ApplicationResources textureForDrawerTopEdge];
    topEdgeLayer.contents = (id)textureForDrawerTopEdge;
    topEdgeLayer.frame = CGRectMake(0, 0, CGImageGetWidth(textureForDrawerTopEdge), CGImageGetHeight(textureForDrawerTopEdge));
    topEdgeLayer.constraints = [NSArray arrayWithObjects:
        [CAConstraint constraintWithAttribute:kCAConstraintMinX relativeTo:@"superlayer" attribute:kCAConstraintMinX],
        [CAConstraint constraintWithAttribute:kCAConstraintMaxX relativeTo:@"superlayer" attribute:kCAConstraintMaxX],
        [CAConstraint constraintWithAttribute:kCAConstraintMaxY relativeTo:@"superlayer" attribute:kCAConstraintMaxY scale:1.0 offset:-50],
        nil
    ];
    [root addSublayer:topEdgeLayer];
    
}

- (void) setContentView:(NSView*)_contentView
{
    if (contentView != _contentView) {

        // Start the animation grouping
        [NSAnimationContext beginGrouping];
        if ([[NSApp currentEvent] modifierFlags] & NSShiftKeyMask) {
            [[NSAnimationContext currentContext] setDuration:2.0];
        }

        NSRect frame = [self frame];
        NSRect superViewFrame = [self.superview frame];
        
        // Add, replace, or remove the content view
        if (contentView && _contentView) {
            [[self animator] replaceSubview:contentView with:_contentView];
        }
        else if (contentView && !_contentView) {
            [[contentView animator] removeFromSuperview];
        }
        else {
            [self addSubview:_contentView];
        }

        [contentView release];
        contentView = [_contentView retain];
        
        if (contentView) {
            CGFloat xPos = (superViewFrame.size.width - [contentView frame].size.width) / 2.0;
            CGFloat yPos = (frame.size.height - minHeight - [contentView frame].size.height);
            NSRect contentViewRect = NSMakeRect(xPos, yPos, [contentView frame].size.width, [contentView frame].size.height);
            [contentView setFrame:contentViewRect];
        }
        
        NSRect viewFrame = [contentView frame];

        if (isOpen && contentView) {
            if (frame.size.height <= minHeight) {
                NSRect newFrame = NSMakeRect(0, -viewFrame.size.height, superViewFrame.size.width, viewFrame.size.height + minHeight);
                NSRect newUpperViewFrame = NSMakeRect(0, newFrame.size.height, superViewFrame.size.width, superViewFrame.size.height - newFrame.size.height);

                [self setFrame:newFrame];

                [button setFrameCenterRotation:45.0];
                [upperView setFrame:newUpperViewFrame];
                [[self animator] setFrame:NSOffsetRect(newFrame, 0, viewFrame.size.height)];
            }
            else {
                NSRect newFrame = NSMakeRect(0, 0, superViewFrame.size.width, viewFrame.size.height + minHeight);
                NSRect newUpperViewFrame = NSMakeRect(0, newFrame.size.height, superViewFrame.size.width, superViewFrame.size.height - newFrame.size.height);
                
                CGFloat offset = 0.0;
                if (newFrame.size.height > frame.size.height) {
                    offset = frame.size.height - newFrame.size.height;
                    newFrame = NSMakeRect(0, offset, superViewFrame.size.width, viewFrame.size.height + minHeight);
                    [self setFrame:newFrame];
                }
                
                [button setFrameCenterRotation:45.0];
                [upperView setFrame:newUpperViewFrame];
                [[self animator] setFrame:NSOffsetRect(newFrame, 0, -offset)];
            }
        }
        else {
            NSRect newFrame = NSMakeRect(0, 0, superViewFrame.size.width, minHeight);
            NSRect newUpperViewFrame = NSMakeRect(0, minHeight, superViewFrame.size.width, superViewFrame.size.height - minHeight);
            
            [button setFrameCenterRotation:0.0];
            [upperView setFrame:newUpperViewFrame];
            [[self animator] setFrame:NSOffsetRect(newFrame, 0, 0)];
        }
        
        [NSAnimationContext endGrouping];
    }
}

- (void) openDrawer
{
    [self setIsOpen:YES];
}

- (void) closeDrawer
{
    [self setIsOpen:NO];
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
