//
//  PageNumberLayer.m
//  Multiplex
//
//  Created by David Martorana on 10/8/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "PageNumberLayer.h"


@implementation PageNumberLayer

@synthesize pageNumber;

- (PageNumberLayer*) init
{
    if (self = [super init]) {
        self.layoutManager = [CAConstraintLayoutManager layoutManager];
        pageNumberTextLayer = [[CATextLayer layer] retain];
        pageNumberTextLayer.font = [NSFont boldSystemFontOfSize:16.0];
        pageNumberTextLayer.fontSize = 16.0;
        pageNumberTextLayer.foregroundColor = CGColorCreateGenericRGB(231.0/255.0, 111.0/255.0, 52.0/255.0, 1.0);
        pageNumberTextLayer.constraints = [NSArray arrayWithObjects:
                                           [CAConstraint constraintWithAttribute:kCAConstraintMidX relativeTo:@"superlayer" attribute:kCAConstraintMidX],
                                           [CAConstraint constraintWithAttribute:kCAConstraintMidY relativeTo:@"superlayer" attribute:kCAConstraintMidY],
                                           nil];
        [self addSublayer:pageNumberTextLayer];
    }
    
    return self;
}

- (void) dealloc
{
    [pageNumberTextLayer release];
    [super dealloc];
}

- (void) setPageNumber:(int)num
{
    pageNumber = num;
    NSString* number = [[NSNumber numberWithInt:pageNumber] stringValue];
    pageNumberTextLayer.string = number;
}

@end
