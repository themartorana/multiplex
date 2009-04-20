#import "MainWindowContentView.h"


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
    //[applicationController toggleFullScreen:self];
    if ([self isInFullScreenMode]) {
        [self exitFullScreenModeWithOptions:nil];
        [toggleFullScreenButton setImage:[NSImage imageNamed:@"NSEnterFullScreenTemplate"]];
    }
    else {
        [self enterFullScreenMode:[NSScreen mainScreen] withOptions:nil];
        [toggleFullScreenButton setImage:[NSImage imageNamed:@"NSExitFullScreenTemplate"]];
    }

    
    // TODO: Hacktastic.  Think about using a custom window
    // SEE: http://cocoadevcentral.com/articles/000028.php
    [[self window] setAutorecalculatesKeyViewLoop:NO];
    [[self window] setInitialFirstResponder:mainView];
    [mainView setNextKeyView:searchField];
    [searchField setNextKeyView:mainView];
    
    [self setNeedsDisplay:YES];
    
    NSLog(@"%@", [[self window] firstResponder]);
    
    [[self window] makeFirstResponder:mainView];
}

- (IBAction) toggleFullScreen:(id)sender
{
    [self toggleFullScreen];
}

@end
