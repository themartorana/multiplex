//
//  InfoButtonLayer.m
//  Multiplex
//
//  Created by David Martorana on 10/1/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "InfoButtonLayer.h"


@implementation InfoButtonLayer

- (InfoButtonLayer*) init
{
    if (self = [super init]) {
        // Load our play button image
        NSString* path = [[NSBundle mainBundle] pathForResource:@"search120x120" ofType:@"pdf"];
        NSURL* url = [NSURL fileURLWithPath:path];
        NSImage* img = [[NSImage alloc] initWithContentsOfURL:url];
        
        CIImage* image = [CIImage imageWithData:[img TIFFRepresentation]];
        CIContext* ciContext = [[[NSApplication sharedApplication] context] CIContext];
        infoButtonImage = [ciContext createCGImage:image fromRect:[image extent]];
    }
    
    [self setNeedsDisplay];
    
    return self;
}

- (void) drawInContext:(CGContextRef)c
{
    CGContextDrawImage(c, self.bounds, infoButtonImage);
}

@end
