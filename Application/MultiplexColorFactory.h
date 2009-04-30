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
+ (CGColorRef) setIndicatorColor;

+ (CGColorRef) multiplexOrange;
+ (CGColorRef) multiplexOrangeSlightlyTransparent;
+ (NSColor*) multiplexYellowOrange;
+ (CGColorRef) multiplexYellowOrangeAsCGColor;

@end
