#import "IHLZoomableWindow.h"
#import <Carbon/Carbon.h>


@implementation IHLZoomableWindow

@synthesize isInFullScreen;

- (NSRect)fullscreenFrame
{
    NSRect newContentRect = [[self screen] frame];
    NSRect rect = [NSWindow frameRectForContentRect:newContentRect styleMask:[self styleMask]];
    return rect;
}

- (void)enterFullScreen
{
    isInFullScreen = YES;
    SetSystemUIMode(kUIModeAllHidden, kUIOptionAutoShowMenuBar);
    originalFrame = [self frame];
    
    [self setShowsResizeIndicator:NO];
    [self setFrame:[self fullscreenFrame] display:YES animate:YES];
}

- (void)returnToOriginal
{
    isInFullScreen = NO;
    [self setShowsResizeIndicator:YES];
    [self setFrame:originalFrame display:YES animate:YES];
    SetSystemUIMode(kUIModeNormal, 0);
}

- (void)toggleFullScreen
{
    if (isInFullScreen) {
        [self returnToOriginal];
    } else {
        [self enterFullScreen]; 
    }
}

- (NSRect) constrainFrameRect:(NSRect)frameRect toScreen:(NSScreen*)screen
{
    if (isInFullScreen) {
        return [self fullscreenFrame];
    }
    else {
        return [super constrainFrameRect:frameRect toScreen:screen];
    }
}

@end
