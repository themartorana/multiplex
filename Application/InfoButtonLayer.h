//
//  InfoButtonLayer.h
//  Multiplex
//
//  Created by David Martorana on 10/1/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

@interface InfoButtonLayer : CALayer {
    CGImageRef infoButtonImage;
    CGImageRef infoButtonImageDown;
    
    BOOL isMouseDown;
}

@property BOOL isMouseDown;

- (CGImageRef) getImageFromPDF:(NSString*)path;

@end
