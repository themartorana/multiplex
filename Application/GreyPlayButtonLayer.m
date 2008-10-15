#import "GreyPlayButtonLayer.h"
#import "NSImage+Mothership.h"

@implementation GreyPlayButtonLayer

- (GreyPlayButtonLayer*) init
{
    if (self = [super init]) {
        // Load our play button image
        playButtonImage = [NSImage playButtonInactive];
    }
    
    [self setNeedsDisplay];
    return self;
}

- (void) dealloc
{
    [super dealloc];
}

- (void) drawInContext:(CGContextRef)c
{
    CGContextDrawImage(c, self.bounds, playButtonImage);
}


@end
