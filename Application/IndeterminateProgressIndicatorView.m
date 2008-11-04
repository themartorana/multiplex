//
//  IndeterminateProgressIndicatorView.m
//  Multiplex
//
//  Created by David Martorana on 11/1/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "IndeterminateProgressIndicatorView.h"
#import "IndeterminateProgressIndicatorLayer.h"
#import <QuartzCore/QuartzCore.h>

@implementation IndeterminateProgressIndicatorView

- (void) awakeFromNib
{
    progressLayer = [IndeterminateProgressIndicatorLayer layer];
    progressLayer.frame = NSRectToCGRect(self.bounds);
    [self setWantsLayer:YES];
    [[self layer] addSublayer:progressLayer];
}

@end
