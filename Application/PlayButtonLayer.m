//
//  PlayButtonLayer.m
//  Multiplex
//
//  Created by David Martorana on 9/29/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "PlayButtonLayer.h"
#import <QuartzCore/QuartzCore.h>

@implementation PlayButtonLayer

@synthesize isMouseDown;

- (PlayButtonLayer*) init
{
    if (self = [super init]) {
        // Load our play button image
        NSString* path = [[NSBundle mainBundle] pathForResource:@"button-play" ofType:@"pdf"];
        playButtonImage = [self getImageFromPDF:path];
        
        path = [[NSBundle mainBundle] pathForResource:@"button-play-down" ofType:@"pdf"];
        playButtonImageDown = [self getImageFromPDF:path];
    }
    
    [self setNeedsDisplay];
    return self;
}

- (void) dealloc
{
    CGImageRelease(playButtonImage);
    CGImageRelease(playButtonImageDown);
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
