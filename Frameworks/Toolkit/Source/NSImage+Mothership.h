//
//  NSImage+Mothership.h
//  Multiplex
//
//  Created by David Martorana on 10/11/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSImage (Mothership)

+ (CGImageRef) playButton;
+ (CGImageRef) playButtonDown;
+ (CGImageRef) playButtonInactive;

+ (CGImageRef) closeButton;
+ (CGImageRef) closeButtonDown;

+ (CGImageRef) getImageFromPDF:(NSString*)path;

@end
