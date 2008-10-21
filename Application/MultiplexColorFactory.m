#import "MultiplexColorFactory.h"

#import <Toolkit/NSColor+IndyHallLabs.h>

static void _drawPatternImage(void* info, CGContextRef ctx);
static void _releasePatternImage(void* info);
static CGPatternRef _createImagePattern(CGImageRef image);
static CGImageRef _createCGImageFromFile(NSString* path);

@implementation MultiplexColorFactory

+ (CGColorRef) drawerBackgroundPattern
{
    static CGColorRef color = NULL;
    if (!color) {
        CGPatternRef pattern = _createImagePattern(_createCGImageFromFile([[NSBundle mainBundle] pathForResource:@"drawer-background-pattern-96x96" ofType:@"gif"]));
        CGColorSpaceRef space = CGColorSpaceCreatePattern(NULL);
        CGFloat components[1] = { 1.0 };
        color = CGColorCreateWithPattern(space, pattern, components);
        CGColorSpaceRelease(space);
        CGPatternRelease(pattern);
    }
    return color;
}


+ (CGColorRef) white
{
    static CGColorRef color = NULL;
    if (!color) {
        color = CGColorCreateGenericRGB(1.0, 1.0, 1.0, 1.0);
    }
    return color;
}

+ (CGColorRef) whiteOneQuarterTransparent
{
    static CGColorRef color = NULL;
    if (!color) {
        color = CGColorCreateGenericRGB(1.0, 1.0, 1.0, 0.75);
    }
    return color;
}

+ (CGColorRef) whiteHalfTransparent
{
    static CGColorRef color = NULL;
    if (!color) {
        color = CGColorCreateGenericRGB(1.0, 1.0, 1.0, 0.5);
    }
    return color;
}

+ (CGColorRef) black
{
    static CGColorRef color = NULL;
    if (!color) {
        color = CGColorCreateGenericRGB(0.0, 0.0, 0.0, 1.0);
    }
    return color;
}

+ (CGColorRef) blackOneQuarterTransparent
{
    static CGColorRef color = NULL;
    if (!color) {
        color = CGColorCreateGenericRGB(0.0, 0.0, 0.0, 0.75);
    }
    return color;
}

+ (CGColorRef) blackHalfTransparent
{
    static CGColorRef color = NULL;
    if (!color) {
        color = CGColorCreateGenericRGB(0.0, 0.0, 0.0, 0.5);
    }
    return color;
}

+ (CGColorRef) moveLayerBorderColor
{
    static CGColorRef color = NULL;
    if (!color) {
        color = CGColorCreateGenericRGB(231.0/255.0, 111.0/255.0, 52.0/255.0, 1.0);        
    }
    return color;
}

+ (CGColorRef) unhoveredGrayForDisc
{
    static CGColorRef color = NULL;
    if (!color) {
        color = CGColorCreateGenericRGB(0.6, 0.6, 0.6, 1.0);
    }
    return color;
}

+ (CGColorRef) softEditTextFieldBGColor
{
    static CGColorRef color = NULL;
    if (!color) {
        color = CGColorCreateGenericRGB(0.7, 0.7, 0.7, 1.0);
    }
    return color;    
}

+ (CGColorRef) softEditTextFieldBorderColor
{
    static CGColorRef color = NULL;
    if (!color) {
        color = CGColorCreateGenericRGB(0.7, 0.7, 0.7, 0.25);
    }
    return color;
}

+ (CGColorRef) discPlayLayerUnhoveredForegroundColor
{
    static CGColorRef color = NULL;
    if (!color) {
        color = CGColorCreateGenericRGB(0.6, 0.6, 0.6, 1.0);
    }
    return color;
}

+ (CGColorRef) multiplexOrange
{
    static CGColorRef color = NULL;
    if (!color) {
        color = CGColorCreateGenericRGB(230.0/255.0, 111.0/255.0, 51.0/255.0, 1.0);
    }
    return color;
}

+ (CGColorRef) multiplexOrangeSlightlyTransparent
{
    static CGColorRef color = NULL;
    if (!color) {
        color = CGColorCreateGenericRGB(230.0/255.0, 111.0/255.0, 51.0/255.0, 0.9);
    }
    return color;
}

+ (NSColor*) multiplexYellowOrange
{
    static NSColor* color = nil;
    if (!color) {
        color = [NSColor colorWithRGBIn0To255ValuesForRed:239 green:168 blue:52 alpha:255];
    }
    return color;
}

@end

#pragma mark -

static void _drawPatternImage(void* info, CGContextRef ctx)
{
    CGImageRef image = (CGImageRef)info;
    CGContextDrawImage(ctx, CGRectMake(0,0, CGImageGetWidth(image), CGImageGetHeight(image)), image);
}

static void _releasePatternImage(void* info)
{
    CGImageRelease((CGImageRef)info);
}

static CGPatternRef _createImagePattern(CGImageRef image)
{
    NSCParameterAssert(image);
    int width = CGImageGetWidth(image);
    int height = CGImageGetHeight(image);
    static const CGPatternCallbacks callbacks = { 0, &_drawPatternImage, &_releasePatternImage };
    return CGPatternCreate(image,
        CGRectMake (0, 0, width, height),
        CGAffineTransformMake (1, 0, 0, 1, 0, 0),
        width,
        height,
        kCGPatternTilingConstantSpacing,
        true,
        &callbacks
    );
}
        
static CGImageRef _createCGImageFromFile(NSString *path)
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

