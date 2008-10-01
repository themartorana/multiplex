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

- (PlayButtonLayer*) init
{
    if (self = [super init]) {
        // Load our play button image
        NSString* path = [[NSBundle mainBundle] pathForResource:@"button-play" ofType:@"pdf"];
        NSURL* url = [NSURL fileURLWithPath:path];
        NSImage* img = [[NSImage alloc] initWithContentsOfURL:url];
        
        CIImage* image = [CIImage imageWithData:[img TIFFRepresentation]];
        CIContext* ciContext = [[[NSApplication sharedApplication] context] CIContext];
        playButtonImage = [ciContext createCGImage:image fromRect:[image extent]];
        
        //self.backgroundColor = CGColorCreateGenericRGB(1.0, 1.0, 1.0, 1.0);
        //self.anchorPoint = CGPointZero;
    }
    
    [self setNeedsDisplay];
    
    return self;
}

- (void) drawInContext:(CGContextRef)c
{
    CGContextDrawImage(c, self.bounds, playButtonImage);
}

@end
