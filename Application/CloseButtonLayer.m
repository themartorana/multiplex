//
//  CloseButtonLayer.m
//  Multiplex
//
//  Created by David Martorana on 10/7/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "CloseButtonLayer.h"


@implementation CloseButtonLayer

@synthesize isMouseDown;

- (CloseButtonLayer*) init
{
    if (self = [super init]) {
        // Load our play button image
        NSString* path = [[NSBundle mainBundle] pathForResource:@"button-play" ofType:@"pdf"];
        closeButtonImage = [self getImageFromPDF:path];
        
        path = [[NSBundle mainBundle] pathForResource:@"button-play-down" ofType:@"pdf"];
        closeButtonImageDown = [self getImageFromPDF:path];
    }
    
    [self setNeedsDisplay];
    return self;
}

- (void) dealloc
{
    CGImageRelease(closeButtonImage);
    CGImageRelease(closeButtonImageDown);
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
        CGContextDrawImage(c, self.bounds, closeButtonImage);
    else
        CGContextDrawImage(c, self.bounds, closeButtonImageDown);
}


@end
