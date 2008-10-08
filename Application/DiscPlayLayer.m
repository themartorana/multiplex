//
//  untitled.m
//  Multiplex
//
//  Created by David Martorana on 10/8/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "DiscPlayLayer.h"
#import "PlayButtonLayer.h"
#import "Disc.h"
#import <QuartzCore/QuartzCore.h>

@implementation DiscPlayLayer

- (DiscPlayLayer*) init
{
    self.anchorPoint = CGPointZero;
    self.bounds = CGRectMake(0.0, 0.0, 367.0, 119.0);
    self.layoutManager = [CAConstraintLayoutManager layoutManager];
    
    playButtonLayer = [[PlayButtonLayer layer] retain];
    playButtonLayer.anchorPoint = CGPointZero;
    playButtonLayer.frame = CGRectMake(367.0 - 76.0 - 20.0, 
                                       (367.0/2.0) - (76.0/2.0), 
                                       76.0, 
                                       76.0);
    
    discNumberTitle = [[CATextLayer layer] retain];
    descriptionLayer = [[CATextLayer layer] retain];
    
    return self;
}


@end
