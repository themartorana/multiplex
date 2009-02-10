#import "PreferencesWindow.h"


@implementation PreferencesWindow

- (void) awakeFromNib
{
    [self center];
}

- (void) keyDown: (NSEvent *) event
{
    [super keyDown:event];
    if ([event keyCode] == 53) /* ESC */ {
        [self close];
    }
}

- (void) close
{
    [self makeFirstResponder:nil];  //  Essentially saves preferences
    [super close];
}

@end
