#import "MainWindowContentView.h"
#import "ZoomableWindow.h"

@implementation MainWindowContentView

- (BOOL) performKeyEquivalent:(NSEvent*)theEvent
{
    switch ([theEvent keyCode]) {
        case 3:
            // "F" - check for COMMAND button
            if ([theEvent modifierFlags] & NSCommandKeyMask) {
                // Put the cursor in the search box
                [[self window] makeFirstResponder:searchField];
                return YES;
            }
            break;
        case 36:
            // The Enter key - if cmd-enter, toggle full screen
            if ([theEvent modifierFlags] & NSCommandKeyMask) {
                [applicationController removeToolTipWindow];
                [[NSRunLoop currentRunLoop] performSelector:@selector(toggleFullScreen) 
                                                     target:self 
                                                   argument:nil 
                                                      order:0 
                                                      modes:[NSArray arrayWithObject:NSDefaultRunLoopMode]];
                return YES;
            }
            break;
        case 34:
            // Open/close the drawer
            if ([theEvent modifierFlags] & NSCommandKeyMask) {
                if ([applicationController isDrawerViewOpen]) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"MultiplexCloseDrawerView" object:nil];
                }
                else {
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"MultiplexShowMovieDialog" object:nil];
                }
                return YES;
            }
            break;
        case 53:
            // Just remove any tooltip windows
            [applicationController removeToolTipWindow];
    }
    
    return NO;
}

- (void) toggleFullScreen
{
    if ([[NSApp mainWindow] isBig]) {
        [toggleFullScreenButton setImage:[NSImage imageNamed:@"NSEnterFullScreenTemplate"]];
    }
    else {
        [toggleFullScreenButton setImage:[NSImage imageNamed:@"NSExitFullScreenTemplate"]];
    }

    [NSWindow swizzleZoomerMethods];
    [[NSApp keyWindow] toggleMegaZoom];
}

- (IBAction) toggleFullScreen:(id)sender
{
    [self toggleFullScreen];
}

@end
