//
//  CGColorManager.m
//  Multiplex
//
//  Created by David Martorana on 10/14/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MultiplexColorFactory.h"

#import <Toolkit/NSColor+IndyHallLabs.h>

@implementation MultiplexColorFactory

+ (CGColorRef) white
{
    static CGColorRef color = NULL;
    if (!color) {
        color = CGColorCreateGenericRGB(1.0, 1.0, 1.0, 1.0);
    }
    return color;
}

+ (CGColorRef) whiteOneQuarterTransparent
{
    static CGColorRef color = NULL;
    if (!color) {
        color = CGColorCreateGenericRGB(1.0, 1.0, 1.0, 0.75);
    }
    return color;
}

+ (CGColorRef) whiteHalfTransparent
{
    static CGColorRef color = NULL;
    if (!color) {
        color = CGColorCreateGenericRGB(1.0, 1.0, 1.0, 0.5);
    }
    return color;
}

+ (CGColorRef) black
{
    static CGColorRef color = NULL;
    if (!color) {
        color = CGColorCreateGenericRGB(0.0, 0.0, 0.0, 1.0);
    }
    return color;
}

+ (CGColorRef) blackOneQuarterTransparent
{
    static CGColorRef color = NULL;
    if (!color) {
        color = CGColorCreateGenericRGB(0.0, 0.0, 0.0, 0.75);
    }
    return color;
}

+ (CGColorRef) blackHalfTransparent
{
    static CGColorRef color = NULL;
    if (!color) {
        color = CGColorCreateGenericRGB(0.0, 0.0, 0.0, 0.5);
    }
    return color;
}

+ (CGColorRef) moveLayerBorderColor
{
    static CGColorRef color = NULL;
    if (!color) {
        color = CGColorCreateGenericRGB(231.0/255.0, 111.0/255.0, 52.0/255.0, 1.0);        
    }
    return color;
}

+ (CGColorRef) unhoveredGrayForDisc
{
    static CGColorRef color = NULL;
    if (!color) {
        color = CGColorCreateGenericRGB(0.6, 0.6, 0.6, 1.0);
    }
    return color;
}

+ (CGColorRef) softEditTextFieldBGColor
{
    static CGColorRef color = NULL;
    if (!color) {
        color = CGColorCreateGenericRGB(0.7, 0.7, 0.7, 1.0);
    }
    return color;    
}

+ (CGColorRef) softEditTextFieldBorderColor
{
    static CGColorRef color = NULL;
    if (!color) {
        color = CGColorCreateGenericRGB(0.7, 0.7, 0.7, 0.25);
    }
    return color;
}

+ (CGColorRef) discPlayLayerUnhoveredForegroundColor
{
    static CGColorRef color = NULL;
    if (!color) {
        color = CGColorCreateGenericRGB(0.6, 0.6, 0.6, 1.0);
    }
    return color;
}

+ (CGColorRef) multiplexOrange
{
    static CGColorRef color = NULL;
    if (!color) {
        color = CGColorCreateGenericRGB(230.0/255.0, 111.0/255.0, 51.0/255.0, 1.0);
    }
    return color;
}

+ (CGColorRef) multiplexOrangeSlightlyTransparent
{
    static CGColorRef color = NULL;
    if (!color) {
        color = CGColorCreateGenericRGB(230.0/255.0, 111.0/255.0, 51.0/255.0, 0.9);
    }
    return color;
}

+ (NSColor*) multiplexYellowOrange
{
    static NSColor* color = nil;
    if (!color) {
        color = [NSColor colorWithRGBIn0To255ValuesForRed:239 green:168 blue:52 alpha:255];
    }
    return color;
}

@end
