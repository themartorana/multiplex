#import "GreyPlayButtonLayer.h"


@implementation GreyPlayButtonLayer

- (GreyPlayButtonLayer*) init
{
    if (self = [super init]) {
        // Load our play button image
        NSString* path = [[NSBundle mainBundle] pathForResource:@"play-button-inactive" ofType:@"pdf"];
        playButtonImage = [self getImageFromPDF:path];
    }
    
    [self setNeedsDisplay];
    return self;
}

- (void) dealloc
{
    CGImageRelease(playButtonImage);
    [super dealloc];
}

- (CGImageRef) getImageFromPDF:(NSString*)path
{
    NSURL* url = [NSURL fileURLWithPath:path];
    NSImage* img = [[NSImage alloc] initWithContentsOfURL:url];
    
    CIImage* image = [CIImage imageWithData:[img TIFFRepresentation]];
    CIContext* ciContext = [[[NSApplication sharedApplication] context] CIContext];
    return [ciContext createCGImage:image fromRect:[image extent]];
}


- (void) drawInContext:(CGContextRef)c
{
    CGContextDrawImage(c, self.bounds, playButtonImage);
}


@end
