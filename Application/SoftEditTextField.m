//
//  SoftEditTextField.m
//  Multiplex
//
//  Created by David Martorana on 10/14/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "SoftEditTextField.h"


@implementation SoftEditTextField

- (void) awakeFromNib
{
    [self setDrawsBackground:NO];
    [self setFocusRingType:NSFocusRingTypeNone];
    [self setBordered:NO];
    [self setTextColor:[NSColor whiteColor]];
}

@end
