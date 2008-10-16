#import "ApplicationResources.h"
#import <Quartz/Quartz.h>

static CGImageRef _playButton;
static CGImageRef _playButtonDown;
static CGImageRef _playButtonInactive;
static CGImageRef _closeButton;
static CGImageRef _closeButtonDown;

@implementation ApplicationResources

+ (CGImageRef) CGImageFromPDF:(NSString*)path
{
    NSURL* url = [NSURL fileURLWithPath:path];
    NSImage* img = [[NSImage alloc] initWithContentsOfURL:url];
    
    CIImage* image = [CIImage imageWithData:[img TIFFRepresentation]];
    CIContext* ciContext = [[[NSApplication sharedApplication] context] CIContext];
    return [ciContext createCGImage:image fromRect:[image extent]];
}

+ (CGImageRef) playButton 
{
    if (!_playButton) {
        _playButton = [self CGImageFromPDF:[[NSBundle mainBundle] pathForResource:@"button-play" ofType:@"pdf"]];
    }
    return _playButton;
}

+ (CGImageRef) playButtonDown 
{
    if (!_playButtonDown) {
        _playButtonDown = [self CGImageFromPDF:[[NSBundle mainBundle] pathForResource:@"button-play-down" ofType:@"pdf"]];
    }
    return _playButtonDown;
}

+ (CGImageRef) playButtonInactive 
{
    if (!_playButtonInactive) {
        _playButtonInactive = [self CGImageFromPDF:[[NSBundle mainBundle] pathForResource:@"play-button-inactive" ofType:@"pdf"]];
    }
    return _playButtonInactive;
}

+ (CGImageRef) closeButton 
{
    if (!_closeButton) {
        _closeButton = [self CGImageFromPDF:[[NSBundle mainBundle] pathForResource:@"close128x128" ofType:@"pdf"]];
    }
    return _closeButton;
}

+ (CGImageRef) closeButtonDown 
{
    if (!_closeButtonDown) {
        _closeButtonDown = [self CGImageFromPDF:[[NSBundle mainBundle] pathForResource:@"close-click128x128" ofType:@"pdf"]];
    }
    return _closeButtonDown;
}

@end
