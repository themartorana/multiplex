//
//  InfoButtonLayer.m
//  Multiplex
//
//  Created by David Martorana on 10/1/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "InfoButtonLayer.h"


@implementation InfoButtonLayer

@synthesize isMouseDown;

- (InfoButtonLayer*) init
{
    if (self = [super init]) {
        // Load our play button image
        NSString* path = [[NSBundle mainBundle] pathForResource:@"button-play" ofType:@"pdf"];
        infoButtonImage = [self getImageFromPDF:path];
        
        path = [[NSBundle mainBundle] pathForResource:@"button-play-down" ofType:@"pdf"];
        infoButtonImageDown = [self getImageFromPDF:path];
    }
    
    [self setNeedsDisplay];
    return self;
}

- (void) dealloc
{
    CGImageRelease(infoButtonImage);
    CGImageRelease(infoButtonImageDown);
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
        CGContextDrawImage(c, self.bounds, infoButtonImage);
    else
        CGContextDrawImage(c, self.bounds, infoButtonImageDown);
}

@end
