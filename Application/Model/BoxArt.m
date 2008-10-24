#import "BoxArt.h"

@implementation BoxArt

@dynamic url;
@dynamic type;
@dynamic state;
@dynamic image;
@dynamic imageData;

@dynamic allDiscs;

+ (NSSet*) keyPathsForValuesAffectingValueForImage
{
    return [NSSet setWithObject:@"imageData"];
}

- (void) setImage:(CGImageRef)_image
{
    [self willChangeValueForKey:@"image"];
    [self setPrimitiveValue:(id)_image forKey:@"image"];
    [self didChangeValueForKey:@"image"];

    NSMutableData* data = nil;
    if (_image) {
        data = [NSMutableData data];
        CGImageDestinationRef imageDest = CGImageDestinationCreateWithData((CFMutableDataRef)data, CFSTR("public.png"), 1, NULL);
        if (imageDest) {
            CGImageDestinationAddImage(imageDest, _image, NULL);
            CGImageDestinationFinalize(imageDest);
            CFRelease(imageDest);
        } else {
            [NSException raise:NSStringFromClass([self class]) format:@"%s:%d", __PRETTY_FUNCTION__, __LINE__];
        }
    }
    [self setType:@"public.png"];
    [self setImageData:data];
}

- (CGImageRef) image
{
    [self willAccessValueForKey:@"image"];
    CGImageRef _image = (CGImageRef)[self primitiveValueForKey:@"image"];
    [self didAccessValueForKey:@"image"];
    if (!_image) {
        NSData* imageData = [self imageData];
        if (imageData != nil) {
            CGImageSourceRef imageSource = CGImageSourceCreateWithData((CFDataRef)imageData, NULL);
            if (imageSource) {
                _image = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
                CFRelease(imageSource);
                [self setPrimitiveValue:(id)_image forKey:@"image"];
            }
        }
    }
    return _image;
}


@end
