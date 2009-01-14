//
//  CGColorManager.h
//  Multiplex
//
//  Created by David Martorana on 10/14/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MultiplexColorFactory : NSObject 

+ (CGColorRef) CGColorFromCGImage:(CGImageRef)image;

+ (CGColorRef) drawerBackgroundPattern;
+ (CGColorRef) drawerBackgroundBaseColor;

+ (CGColorRef) white;
+ (CGColorRef) black;
+ (CGColorRef) clear;

+ (CGColorRef) whiteOneQuarterTransparent;
+ (CGColorRef) whiteHalfTransparent;
+ (CGColorRef) whiteThreeQuartersTransparent;
+ (CGColorRef) blackOneQuarterTransparent;
+ (CGColorRef) blackHalfTransparent;
+ (CGColorRef) blackThreeQuartersTransparent;

+ (CGColorRef) moveLayerBorderColor;
+ (CGColorRef) unhoveredGrayForDisc;
+ (CGColorRef) softEditTextFieldBGColor;
+ (CGColorRef) softEditTextFieldBorderColor;
+ (CGColorRef) discPlayLayerUnhoveredForegroundColor;

+ (CGColorRef) multiplexOrange;
+ (CGColorRef) multiplexOrangeSlightlyTransparent;
+ (NSColor*) multiplexYellowOrange;
+ (CGColorRef) multiplexYellowOrangeAsCGColor;

@end
