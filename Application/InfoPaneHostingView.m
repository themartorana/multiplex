//
//  InfoPaneHostingView.m
//  Multiplex
//
//  Created by David Martorana on 10/6/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "InfoPaneHostingView.h"
#import "Movie.h"

@implementation InfoPaneHostingView

- (void) awakeFromNib 
{
    [self setWantsLayer:YES];
    [[self layer] setBackgroundColor:CGColorCreateGenericRGB(0.0, 0.0, 0.0, 0.4)];
}

@end

