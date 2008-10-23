#import "ApplicationResources.h"
#import <Quartz/Quartz.h>

@implementation ApplicationResources

+ (CGImageRef) CGImageFromFileAtPath:(NSString*)path
{
    CGImageRef image = NULL;
    CGImageSourceRef src = CGImageSourceCreateWithData((CFDataRef)[NSData dataWithContentsOfFile:path], NULL);
    if (src) {
        image = CGImageSourceCreateImageAtIndex(src, 0, (CFDictionaryRef)[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], kCGImageSourceCreateThumbnailFromImageAlways, nil]);
        CFRelease(src);
        if (!image) {
            NSLog(@"Warning: CGImageFromFile failed on file %@ (ptr size=%u)", path, sizeof(void*));
        }
    }
    return image;
}

+ (CGImageRef) CGImageFromResource:(NSString*)name ofType:(NSString*)type
{
    NSString* path = [[NSBundle mainBundle] pathForResource:name ofType:type];
    if ([type isEqualToString:@"pdf"]) {
        NSURL* url = [NSURL fileURLWithPath:path];
        NSImage* img = [[NSImage alloc] initWithContentsOfURL:url];
        CIImage* image = [CIImage imageWithData:[img TIFFRepresentation]];
        CIContext* ciContext = [[[NSApplication sharedApplication] context] CIContext];
        return [ciContext createCGImage:image fromRect:[image extent]];
    } else {
        return [self CGImageFromFileAtPath:path];
    }
}

+ (CGImageRef) editIcon 
{
    static CGImageRef image = NULL;
    if (!image) {
        image = [self CGImageFromResource:@"edit-icon-16x16" ofType:@"png"];
    }
    return image;
}

+ (CGImageRef) playButton 
{
    static CGImageRef image = NULL;
    if (!image) {
        image = [self CGImageFromResource:@"button-play" ofType:@"pdf"];
    }
    return image;
}

+ (CGImageRef) playButtonDown 
{
    static CGImageRef image = NULL;
    if (!image) {
        image = [self CGImageFromResource:@"button-play-down" ofType:@"pdf"];
    }
    return image;
}

+ (CGImageRef) playButtonInactive 
{
    static CGImageRef image = NULL;
    if (!image) {
        image = [self CGImageFromResource:@"play-button-inactive" ofType:@"pdf"];
    }
    return image;
}

+ (CGImageRef) closeButton 
{
    static CGImageRef image = NULL;
    if (!image) {
        image = [self CGImageFromResource:@"close128x128" ofType:@"pdf"];
    }
    return image;
}

+ (CGImageRef) closeButtonDown 
{
    static CGImageRef image = NULL;
    if (!image) {
        image = [self CGImageFromResource:@"close-click128x128" ofType:@"pdf"];
    }
    return image;
}

@end
