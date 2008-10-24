//
//  HalfTransparentView.m
//  Multiplex
//
//  Created by David Martorana on 10/24/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "HalfTransparentView.h"


@implementation HalfTransparentView

- (void)drawRect:(NSRect)rect {
    NSColor* color = [NSColor colorWithCalibratedRed:0.0 green:0.0 blue:0.0 alpha:0.25];
    [color set];
    NSRectFill(rect);
}

@end
