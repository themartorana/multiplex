#import "ApplicationResources.h"
#import <Quartz/Quartz.h>

@implementation ApplicationResources

+ (CGImageRef) CGImageFromFile:(NSString*)path
{
    CGImageRef image = NULL;
    CGImageSourceRef src = CGImageSourceCreateWithURL((CFURLRef)[NSURL fileURLWithPath:path], NULL);
    if (src) {
        image = CGImageSourceCreateImageAtIndex(src, 0, NULL);
        CFRelease(src);
        if (!image) {
            NSLog(@"Warning: CGImageSourceCreateImageAtIndex failed on file %@ (ptr size=%u)", path, sizeof(void*));
        }
    }
    return image;
}

+ (CGImageRef) CGImageFromPDF:(NSString*)path
{
    NSURL* url = [NSURL fileURLWithPath:path];
    NSImage* img = [[NSImage alloc] initWithContentsOfURL:url];
    
    CIImage* image = [CIImage imageWithData:[img TIFFRepresentation]];
    CIContext* ciContext = [[[NSApplication sharedApplication] context] CIContext];
    return [ciContext createCGImage:image fromRect:[image extent]];
}

+ (CGImageRef) editIcon 
{
    static CGImageRef image = NULL;
    if (!image) {
        image = [self CGImageFromFile:[[NSBundle mainBundle] pathForResource:@"edit-icon-16x16" ofType:@"png"]];
    }
    return image;
}

+ (CGImageRef) playButton 
{
    static CGImageRef image = NULL;
    if (!image) {
        image = [self CGImageFromPDF:[[NSBundle mainBundle] pathForResource:@"button-play" ofType:@"pdf"]];
    }
    return image;
}

+ (CGImageRef) playButtonDown 
{
    static CGImageRef image = NULL;
    if (!image) {
        image = [self CGImageFromPDF:[[NSBundle mainBundle] pathForResource:@"button-play-down" ofType:@"pdf"]];
    }
    return image;
}

+ (CGImageRef) playButtonInactive 
{
    static CGImageRef image = NULL;
    if (!image) {
        image = [self CGImageFromPDF:[[NSBundle mainBundle] pathForResource:@"play-button-inactive" ofType:@"pdf"]];
    }
    return image;
}

+ (CGImageRef) closeButton 
{
    static CGImageRef image = NULL;
    if (!image) {
        image = [self CGImageFromPDF:[[NSBundle mainBundle] pathForResource:@"close128x128" ofType:@"pdf"]];
    }
    return image;
}

+ (CGImageRef) closeButtonDown 
{
    static CGImageRef image = NULL;
    if (!image) {
        image = [self CGImageFromPDF:[[NSBundle mainBundle] pathForResource:@"close-click128x128" ofType:@"pdf"]];
    }
    return image;
}

@end
