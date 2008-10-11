//
//  NSMutableDictionary+Mothership.h
//  Multiplex
//
//  Created by David Martorana on 10/11/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSMutableDictionary (Mothership)

+ (void) addBoxImage:(CGImageRef)image forKey:(id)key;
+ (CGImageRef) boxImageForKey:(id)key;

@end
