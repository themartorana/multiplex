//
//  NSImage+Mothership.m
//  Multiplex
//
//  Created by David Martorana on 10/11/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "NSImage+Mothership.h"
#import <QuartzCore/QuartzCore.h>

static CGImageRef _playButton;
static CGImageRef _playButtonDown;
static CGImageRef _playButtonInactive;

static CGImageRef _closeButton;
static CGImageRef _closeButtonDown;

@implementation NSImage (Mothership)

+ (CGImageRef) playButton {
    if (_playButton) {
        return _playButton;
    }
    else {
        NSString* path = [[NSBundle mainBundle] pathForResource:@"button-play" ofType:@"pdf"];
        _playButton = [NSImage getImageFromPDF:path];
        return _playButton;
    }
}

+ (CGImageRef) playButtonDown {
    if (_playButtonDown) {
        return _playButtonDown;
    }
    else {
        NSString* path = [[NSBundle mainBundle] pathForResource:@"button-play-down" ofType:@"pdf"];
        _playButtonDown = [NSImage getImageFromPDF:path];
        return _playButtonDown;
    }
}

+ (CGImageRef) playButtonInactive {
    if (_playButtonInactive) {
        return _playButtonInactive;
    }
    else {
        NSString* path = [[NSBundle mainBundle] pathForResource:@"play-button-inactive" ofType:@"pdf"];
        _playButtonInactive = [NSImage getImageFromPDF:path];
        return _playButtonInactive;
    }
}

+ (CGImageRef) closeButton {
    if (_closeButton) {
        return _closeButton;
    }
    else {
        NSString* path = [[NSBundle mainBundle] pathForResource:@"close128x128" ofType:@"pdf"];
        _closeButton = [NSImage getImageFromPDF:path];
        return _closeButton;
    }
}

+ (CGImageRef) closeButtonDown {
    if (_closeButtonDown) {
        return _closeButtonDown;
    }
    else {
        NSString* path = [[NSBundle mainBundle] pathForResource:@"close-click128x128" ofType:@"pdf"];
        _closeButtonDown = [NSImage getImageFromPDF:path];
        return _closeButtonDown;
    }
}

+ (CGImageRef) getImageFromPDF:(NSString*)path
{
    NSURL* url = [NSURL fileURLWithPath:path];
    NSImage* img = [[NSImage alloc] initWithContentsOfURL:url];
    
    CIImage* image = [CIImage imageWithData:[img TIFFRepresentation]];
    CIContext* ciContext = [[[NSApplication sharedApplication] context] CIContext];
    return [ciContext createCGImage:image fromRect:[image extent]];
}

@end
