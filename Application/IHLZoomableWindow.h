//
//  Heavily based on ZoomableWindow.h
//  megazoomer
//

#import <Cocoa/Cocoa.h>


@interface IHLZoomableWindow : NSWindow {
    BOOL isInFullScreen;
    BOOL isResizing;
    
    NSRect originalFrame;
}

@property BOOL isInFullScreen;

- (void)enterFullScreen;
- (void)returnToOriginal;

- (void)toggleFullScreen;

- (NSRect)fullscreenFrame;

@end
