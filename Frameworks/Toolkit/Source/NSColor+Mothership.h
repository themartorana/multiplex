//
//  NSColor+Mothership.h
//  Multiplex
//
//  Created by David Martorana on 10/8/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSColor (Mothership)

+ (NSColor*) colorWithRGBIn0To255ValuesForRed:(int)red green:(int)green blue:(int)blue alpha:(int)alpha;

- (CGColorRef) colorAsCGColorRef;

@end
