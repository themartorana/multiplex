#import "PlayButtonLayer.h"
#import "NSImage+Mothership.h"
#import <QuartzCore/QuartzCore.h>

@implementation PlayButtonLayer

@synthesize isMouseDown;

- (PlayButtonLayer*) init
{
    if (self = [super init]) {
        // Load our play button image
        
        playButtonImage = [NSImage playButton];
        playButtonImageDown = [NSImage playButtonDown];
    }
    
    [self setNeedsDisplay];
    return self;
}

- (void) dealloc
{
    [super dealloc];
}

- (void) setIsMouseDown:(BOOL)down
{
    isMouseDown = down;
    [self setNeedsDisplay];
}

- (void) drawInContext:(CGContextRef)c
{
    if (!isMouseDown)
        CGContextDrawImage(c, self.bounds, playButtonImage);
    else
        CGContextDrawImage(c, self.bounds, playButtonImageDown);
}

@end
