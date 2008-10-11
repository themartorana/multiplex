//
//  CloseButtonLayer.h
//  Multiplex
//
//  Created by David Martorana on 10/7/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

@interface CloseButtonLayer : CALayer {
    CGImageRef closeButtonImage;
    CGImageRef closeButtonImageDown;
    
    BOOL isMouseDown;
}

@property BOOL isMouseDown;

@end
