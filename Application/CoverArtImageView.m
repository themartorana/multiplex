#import "CoverArtImageView.h"
#import <Quartz/Quartz.h>

@implementation CoverArtImageView
@synthesize image;

- (void) viewWillMoveToSuperview:(NSView*)newSuperview
{
    [self setWantsLayer:YES];
    [self.layer setDelegate:self];
}

- (id) image
{
    return [[image retain] autorelease];
}

- (void) setImage:(id)_image
{
    if (image != _image) {
        [image release];
        image = [_image retain];
        [self.layer setNeedsDisplay];
    }
}

- (void) drawLayer:(CALayer*)layer inContext:(CGContextRef)c
{
    if (image) {
        CGContextDrawImage(c, layer.bounds, (CGImageRef)image);
    }
}

@end
