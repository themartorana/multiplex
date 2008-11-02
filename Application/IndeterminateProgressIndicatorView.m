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
    CALayer* selfLayer = [self layer];
    
    progressLayer = [IndeterminateProgressIndicatorLayer layer];
    progressLayer.frame = CGRectMake(0, 0, selfLayer.frame.size.width, selfLayer.frame.size.height);

    [self setWantsLayer:YES];
    [selfLayer addSublayer:progressLayer];
}

@end
