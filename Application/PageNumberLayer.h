//
//  PageNumberLayer.h
//  Multiplex
//
//  Created by David Martorana on 10/8/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

@interface PageNumberLayer : CALayer {
    int pageNumber;
    CATextLayer* pageNumberTextLayer;
    NSColor* pageNumberColor;
}

@property int pageNumber;

@end
