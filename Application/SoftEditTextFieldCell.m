#import "SoftEditTextFieldCell.h"
#import "CGColorFactory.h"
#import <Quartz/Quartz.h>

@implementation SoftEditTextFieldCell

- (void) dealloc
{
    [backgroundLayer release];
    [super dealloc];
}

- (CGRect) borderRectForAttributedString:(NSAttributedString*)string inFrame:(CGRect)bounds
{
    //int delta = floor((bounds.size.width - ([string size].width + (10 * 2))) / 2);
    //return (delta < 0) ? CGRectInset(bounds, 0.0, -2.0) : CGRectInset(bounds, delta, -2.0);
    
    return CGRectMake(0.0, 0.0, [string size].width + 10.0, bounds.size.height);
}

- (void) adjustBackgroundLayer
{
    if (fieldEditor) {
        [CATransaction begin];
        [CATransaction setValue:[NSNumber numberWithBool:YES] forKey:kCATransactionDisableActions];
        NSRect frame = [[self controlView] frame];
        CGRect frameForAttributedString = [self borderRectForAttributedString:[fieldEditor attributedString] inFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        [backgroundLayer setFrame:frameForAttributedString];
        [CATransaction commit];
    }
}

- (void) setObjectValue:(id)object
{
    [super setObjectValue:object];
    [self adjustBackgroundLayer];
}

- (void) selectWithFrame:(NSRect)frame inView:(NSView*)controlView editor:(NSText*)editor delegate:(id)delegate start:(NSInteger)start length:(NSInteger)length
{
    if (!backgroundLayer) {
        [controlView setWantsLayer:YES];
        CALayer* viewLayer = [controlView layer];
        
        backgroundLayer = [[CALayer alloc] init];
        [backgroundLayer setBackgroundColor:[CGColorFactory softEditTextFieldBGColor]];
        [backgroundLayer setBorderColor:[CGColorFactory softEditTextFieldBorderColor]];
        [backgroundLayer setCornerRadius:3.0];
        [backgroundLayer setBorderWidth:1.0];
        [viewLayer addSublayer:backgroundLayer];
    }
    fieldEditor = [editor retain];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidEndEditing:) name:NSTextDidEndEditingNotification object:editor];
    [super selectWithFrame:frame inView:controlView editor:editor delegate:delegate start:start length:length];
    [fieldEditor setSelectedTextAttributes:
        [NSDictionary dictionaryWithObjectsAndKeys:
            [NSColor colorWithCalibratedWhite:0.7 alpha:0.5], NSBackgroundColorAttributeName,
            nil
        ]
    ];
    [backgroundLayer setHidden:NO];
    [self adjustBackgroundLayer];
}

- (void) textDidChange:(NSNotification*)notification
{
    [self adjustBackgroundLayer];
}

- (void) textDidEndEditing:(NSNotification*)notification
{
    [fieldEditor release];
    fieldEditor = nil;
    [backgroundLayer setHidden:YES];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
