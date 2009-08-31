#import "DrawerView.h"
#import "MultiplexColorFactory.h"
#import "ApplicationResources.h"
#import <QuartzCore/QuartzCore.h>

@implementation DrawerView
@synthesize isOpen;
@synthesize contentView;
@synthesize upperView;

- (void) awakeFromNib
{
    minHeight = [self frame].size.height;
    /*
    CALayer* root = [self layer];
    [root setZPosition:1000];
    [root setLayoutManager:[CAConstraintLayoutManager layoutManager]];

    CALayer* backgroundLayer = [CALayer layer];
    backgroundLayer.delegate = self;
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
    patternLayer.delegate = self;
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
    topEdgeLayer.delegate = self;
    topEdgeLayer.contents = (id)textureForDrawerTopEdge;
    topEdgeLayer.frame = CGRectMake(0, 0, CGImageGetWidth(textureForDrawerTopEdge), CGImageGetHeight(textureForDrawerTopEdge));
    topEdgeLayer.constraints = [NSArray arrayWithObjects:
        [CAConstraint constraintWithAttribute:kCAConstraintMinX relativeTo:@"superlayer" attribute:kCAConstraintMinX],
        [CAConstraint constraintWithAttribute:kCAConstraintMaxX relativeTo:@"superlayer" attribute:kCAConstraintMaxX],
        [CAConstraint constraintWithAttribute:kCAConstraintMaxY relativeTo:@"superlayer" attribute:kCAConstraintMaxY scale:1.0 offset:-50],
        nil
    ];
    [root addSublayer:topEdgeLayer];
    */
}

- (void) drawRect:(NSRect)rect
{
    /*CALayer* root = [self layer];
     CALayer* backgroundLayer = [CALayer layer];
     backgroundLayer.delegate = self;
     backgroundLayer.contents = (id)[ApplicationResources textureForDrawerBackground];
     backgroundLayer.constraints = [NSArray arrayWithObjects:
     [CAConstraint constraintWithAttribute:kCAConstraintMinX relativeTo:@"superlayer" attribute:kCAConstraintMinX],
     [CAConstraint constraintWithAttribute:kCAConstraintMinY relativeTo:@"superlayer" attribute:kCAConstraintMinY],
     [CAConstraint constraintWithAttribute:kCAConstraintMaxX relativeTo:@"superlayer" attribute:kCAConstraintMaxX],
     [CAConstraint constraintWithAttribute:kCAConstraintMaxY relativeTo:@"superlayer" attribute:kCAConstraintMaxY scale:1.0 offset:-50],
     nil
     ];
     [root addSublayer:backgroundLayer];
     */
    
    // Draw background
    NSColor* bgcolor1 = [NSColor colorWithDeviceRed:31.0/255.0 green:31.0/255.0 blue:31.0/255.0 alpha:1.0];
    NSColor* bgcolor2 = [NSColor colorWithDeviceRed:71.0/255.0 green:71.0/255.0 blue:71.0/255.0 alpha:1.0];
    NSGradient* gradient = [[NSGradient alloc] initWithColorsAndLocations:bgcolor1, (CGFloat)0.0, bgcolor2, (CGFloat)0.5, bgcolor1, (CGFloat)1.0, nil];
    [gradient drawInRect:[self bounds] angle:0.0];
    [gradient release];
    
    /*
     
     CALayer* patternLayer = [CALayer layer];
     patternLayer.delegate = self;
     patternLayer.backgroundColor = [MultiplexColorFactory drawerBackgroundPattern];
     patternLayer.constraints = [NSArray arrayWithObjects:
     [CAConstraint constraintWithAttribute:kCAConstraintMinX relativeTo:@"superlayer" attribute:kCAConstraintMinX],
     [CAConstraint constraintWithAttribute:kCAConstraintMinY relativeTo:@"superlayer" attribute:kCAConstraintMinY],
     [CAConstraint constraintWithAttribute:kCAConstraintMaxX relativeTo:@"superlayer" attribute:kCAConstraintMaxX],
     [CAConstraint constraintWithAttribute:kCAConstraintMaxY relativeTo:@"superlayer" attribute:kCAConstraintMaxY scale:1.0 offset:-52],
     nil
     ];
     [root addSublayer:patternLayer];
     */
    
    // Draw the pattern
    [[NSColor colorWithPatternImage:[NSImage imageNamed:@"drawer-background-pattern-96x96.gif"]] set]; 
    [NSBezierPath fillRect:NSMakeRect(0, 0, [self bounds].size.width, [self bounds].size.height - 52)];
    
    /*
     CALayer* topEdgeLayer = [CALayer layer];
     CGImageRef textureForDrawerTopEdge = [ApplicationResources textureForDrawerTopEdge];
     topEdgeLayer.delegate = self;
     topEdgeLayer.contents = (id)textureForDrawerTopEdge;
     topEdgeLayer.frame = CGRectMake(0, 0, CGImageGetWidth(textureForDrawerTopEdge), CGImageGetHeight(textureForDrawerTopEdge));
     topEdgeLayer.constraints = [NSArray arrayWithObjects:
     [CAConstraint constraintWithAttribute:kCAConstraintMinX relativeTo:@"superlayer" attribute:kCAConstraintMinX],
     [CAConstraint constraintWithAttribute:kCAConstraintMaxX relativeTo:@"superlayer" attribute:kCAConstraintMaxX],
     [CAConstraint constraintWithAttribute:kCAConstraintMaxY relativeTo:@"superlayer" attribute:kCAConstraintMaxY scale:1.0 offset:-50],
     nil
     ];
     [root addSublayer:topEdgeLayer];
     */
    
    // Draw the top edge
    int W = [self bounds].size.width;
    int H = [self bounds].size.height - 50;
    NSColor* color1 = [NSColor colorWithDeviceRed:171.0/255.0 green:171.0/255.0 blue:171.0/255.0 alpha:1.0];
    NSColor* color2 = [NSColor colorWithDeviceRed:15.0/255.0 green:15.0/255.0 blue:15.0/255.0 alpha:1.0];
    NSColor* color3 = [NSColor colorWithCalibratedWhite:0.0 alpha:0.30];
    NSColor* color4 = [NSColor colorWithCalibratedWhite:0.0 alpha:0];
    
    [color1 set];
    NSBezierPath* line1 = [NSBezierPath bezierPath];
    [line1 setLineWidth:1.0];
    [line1 moveToPoint:NSMakePoint(0, H)];
    [line1 lineToPoint:NSMakePoint(W, H)];
    [line1 stroke];
    
    [color2 set];
    NSBezierPath* line2 = [NSBezierPath bezierPath];
    [line2 setLineWidth:1.0];
    [line2 moveToPoint:NSMakePoint(0, H - 1)];
    [line2 lineToPoint:NSMakePoint(W, H - 1)];
    [line2 stroke];
    
    gradient = [[NSGradient alloc] initWithColorsAndLocations:color4, (CGFloat)0.0, color3, (CGFloat)1.0, nil];
    [gradient drawInRect:NSMakeRect(0, [self bounds].size.height - 66, [self bounds].size.width, 15) angle:90.0];
    [gradient release];
}

- (id<CAAction>) actionForLayer:(CALayer*)layer forKey:(NSString*)key
{
    /*  Effectively disable all animations on layers for which we are the
     *  delegate.
     */
    return [CAAnimation animation];
}

- (void) setContentView:(NSView*)_contentView
{
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
    } else if (contentView && !_contentView) {
        [[contentView animator] removeFromSuperview];
    } else {
        [self addSubview:_contentView];
    }

    [contentView release];
    contentView = [_contentView retain];
    
    if (contentView) {
        CGFloat xPos = ceilf((superViewFrame.size.width - [contentView frame].size.width) / 2.0);
        CGFloat yPos = ceilf((frame.size.height - minHeight - [contentView frame].size.height));
        NSRect contentViewRect = NSMakeRect(xPos, yPos, [contentView frame].size.width, [contentView frame].size.height);
        [contentView setFrame:contentViewRect];
    }
    
    NSRect viewFrame = [contentView frame];

    if (isOpen && contentView) {
        if (frame.size.height <= minHeight) {
            NSRect newFrame = NSMakeRect(0, -viewFrame.size.height, superViewFrame.size.width, viewFrame.size.height + minHeight);
            NSRect newUpperViewFrame = NSMakeRect(0, newFrame.size.height, superViewFrame.size.width, superViewFrame.size.height - newFrame.size.height);

            [self setFrame:newFrame];

            //[button setFrameCenterRotation:45.0];
            [upperView setFrame:newUpperViewFrame];
            [[self animator] setFrame:NSOffsetRect(newFrame, 0, viewFrame.size.height)];
        } else {
            NSRect newFrame = NSMakeRect(0, 0, superViewFrame.size.width, viewFrame.size.height + minHeight);
            NSRect newUpperViewFrame = NSMakeRect(0, newFrame.size.height, superViewFrame.size.width, superViewFrame.size.height - newFrame.size.height);
            
            CGFloat offset = 0.0;
            if (newFrame.size.height > frame.size.height) {
                offset = frame.size.height - newFrame.size.height;
                newFrame = NSMakeRect(0, offset, superViewFrame.size.width, viewFrame.size.height + minHeight);
                [self setFrame:newFrame];
            }
            
            //[button setFrameCenterRotation:45.0];
            [upperView setFrame:newUpperViewFrame];
            [[self animator] setFrame:NSOffsetRect(newFrame, 0, -offset)];
        }
    } else {
        NSRect newFrame = NSMakeRect(0, 0, superViewFrame.size.width, minHeight);
        NSRect newUpperViewFrame = NSMakeRect(0, minHeight, superViewFrame.size.width, superViewFrame.size.height - minHeight);
        
        [button setFrameCenterRotation:0.0];
        [upperView setFrame:newUpperViewFrame];
        [[self animator] setFrame:NSOffsetRect(newFrame, 0, 0)];
    }
    
    [NSAnimationContext endGrouping];
}

- (void) openDrawer
{
    [self setIsOpen:YES];
    [button setTitle:@"▼ Hide Info"];
}

- (void) closeDrawer
{
    [self setIsOpen:NO];
    [button setTitle:@"▲ Show Info"];
}

- (IBAction) toggle:(id)sender
{
    if (isOpen) {
        //[self closeDrawer];
        // Allow the app controller to take this over
        [[NSNotificationCenter defaultCenter] postNotificationName:@"MultiplexCloseDrawerView" object:nil];
    } else {
        [self openDrawer];
    }
}

@end
