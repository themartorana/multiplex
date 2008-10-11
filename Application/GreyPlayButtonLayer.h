//
//  untitled.h
//  Multiplex
//
//  Created by David Martorana on 10/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

@interface GreyPlayButtonLayer : CALayer {
    CGImageRef playButtonImage;
}

@property BOOL isMouseDown;

- (CGImageRef) getImageFromPDF:(NSString*)path;

@end
