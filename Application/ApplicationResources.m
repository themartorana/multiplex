#import "ApplicationResources.h"
#import <Quartz/Quartz.h>
#import <WebKit/WebKit.h>

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

+ (CGImageRef) fullScreenButton 
{
    static CGImageRef image = NULL;
    if (!image) {
        image = [self CGImageFromResource:@"full-screen-icon" ofType:@"gif"];
    }
    return image;
}

+ (CGImageRef) fullScreenButtonDown 
{
    static CGImageRef image = NULL;
    if (!image) {
        image = [self CGImageFromResource:@"full-screen-icon-down" ofType:@"gif"];
    }
    return image;
}

+ (CGImageRef) textureForStadiumLayoutFloor
{
    static CGImageRef image = NULL;
    if (!image) {
        const int W = 100, H = 100;
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        void* bits = calloc(W * H, 4);
        NSAssert(bits, @"no bits!");
        CGContextRef c = CGBitmapContextCreate(bits, W, H, 8, W * 4, colorSpace, kCGImageAlphaPremultipliedFirst);
        CGColorSpaceRelease(colorSpace);
        
        [NSGraphicsContext saveGraphicsState];
        [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithGraphicsPort:c flipped:YES]];
        {
            NSPoint center = NSMakePoint(W / 2.0, H / 2.0);
            NSColor* lightGrey = [NSColor colorWithDeviceRed:154.0/255.0 green:154.0/255.0 blue:154.0/255.0 alpha:1.0];
            NSColor* darkGrey = [NSColor colorWithDeviceRed:154.0/255.0 green:154.0/255.0 blue:154.0/255.0 alpha:0.0];
            NSGradient* gradient = [[NSGradient alloc] initWithColorsAndLocations:lightGrey, (CGFloat)0.0, darkGrey, (CGFloat)1.0, nil];
            [gradient drawFromCenter:center radius:0 toCenter:center radius:MIN(W, H)/2.0 options:0];
            [gradient release];
        }
        [NSGraphicsContext restoreGraphicsState];
        image = CGBitmapContextCreateImage(c);
        CGContextRelease(c);
        free(bits);
    }
    return image;
}

+ (CGImageRef) textureForDrawerBackground
{
    static CGImageRef image = NULL;
    if (!image) {
        const int W = 100, H = 100;
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        void* bits = calloc(W * H, 4);
        NSAssert(bits, @"no bits!");
        CGContextRef c = CGBitmapContextCreate(bits, W, H, 8, W * 4, colorSpace, kCGImageAlphaPremultipliedFirst);
        CGColorSpaceRelease(colorSpace);
        
        [NSGraphicsContext saveGraphicsState];
        [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithGraphicsPort:c flipped:YES]];
        {
            NSColor* color1 = [NSColor colorWithDeviceRed:31.0/255.0 green:31.0/255.0 blue:31.0/255.0 alpha:1.0];
            NSColor* color2 = [NSColor colorWithDeviceRed:71.0/255.0 green:71.0/255.0 blue:71.0/255.0 alpha:1.0];
            
            NSGradient* gradient = [[NSGradient alloc] initWithColorsAndLocations:color1, (CGFloat)0.0, color2, (CGFloat)0.5, color1, (CGFloat)1.0, nil];
            [gradient drawInRect:NSMakeRect(0, 0, W, H) angle:145.0];
            [gradient release];
        }
        [NSGraphicsContext restoreGraphicsState];
        image = CGBitmapContextCreateImage(c);
        CGContextRelease(c);
        free(bits);
    }
    return image;
}

+ (CGImageRef) textureForDrawerTopEdge
{
    static CGImageRef image = NULL;
    if (!image) {
        const int W = 100, H = 15;
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        void* bits = calloc(W * H, 4);
        NSAssert(bits, @"no bits!");
        CGContextRef c = CGBitmapContextCreate(bits, W, H, 8, W * 4, colorSpace, kCGImageAlphaPremultipliedFirst);
        CGColorSpaceRelease(colorSpace);
        
        [NSGraphicsContext saveGraphicsState];
        [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithGraphicsPort:c flipped:YES]];
        {
            NSColor* color1 = [NSColor colorWithDeviceRed:171.0/255.0 green:171.0/255.0 blue:171.0/255.0 alpha:1.0];
            NSColor* color2 = [NSColor colorWithDeviceRed:15.0/255.0 green:15.0/255.0 blue:15.0/255.0 alpha:1.0];
            NSColor* color3 = [NSColor colorWithCalibratedWhite:0.0 alpha:0.25];
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

            NSGradient* gradient = [[NSGradient alloc] initWithColorsAndLocations:color4, (CGFloat)0.0, color3, (CGFloat)1.0, nil];
            [gradient drawInRect:NSMakeRect(0, 0, W, H - 2) angle:90.0];
            [gradient release];
        }
        [NSGraphicsContext restoreGraphicsState];
        image = CGBitmapContextCreateImage(c);
        CGContextRelease(c);
        free(bits);
    }
    return image;
}

+ (WebPreferences*) userVoiceWebPreferences
{
    WebPreferences* prefs = [[WebPreferences alloc] init];
    [prefs setUserStyleSheetEnabled:YES];
    [prefs setJavaEnabled:NO];
    [prefs setPlugInsEnabled:NO];
    [prefs setUserStyleSheetLocation:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"uservoice-feedback" ofType:@"css"]]];   
    return prefs;
}

+ (WebPreferences*) movieDescriptionWebPreferences
{
    WebPreferences* prefs = [[WebPreferences alloc] init];
    [prefs setJavaEnabled:NO];
    [prefs setJavaScriptEnabled:NO];
    [prefs setPlugInsEnabled:NO];
    [prefs setUserStyleSheetEnabled:YES];
    [prefs setUserStyleSheetLocation:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"movie-description" ofType:@"css"]]];   
    return prefs;
}

@end
