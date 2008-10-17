//
//  CGColorManager.h
//  Multiplex
//
//  Created by David Martorana on 10/14/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MultiplexColorFactory : NSObject 

+ (CGColorRef) white;
+ (CGColorRef) black;

+ (CGColorRef) whiteOneQuarterTransparent;
+ (CGColorRef) whiteHalfTransparent;
+ (CGColorRef) blackOneQuarterTransparent;
+ (CGColorRef) blackHalfTransparent;

+ (CGColorRef) moveLayerBorderColor;
+ (CGColorRef) unhoveredGrayForDisc;
+ (CGColorRef) softEditTextFieldBGColor;
+ (CGColorRef) softEditTextFieldBorderColor;
+ (CGColorRef) discPlayLayerUnhoveredForegroundColor;

+ (CGColorRef) multiplexOrange;
+ (CGColorRef) multiplexOrangeSlightlyTransparent;
+ (NSColor*) multiplexYellowOrange;

@end
