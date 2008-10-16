#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

@interface ButtonLayer : CALayer {
    BOOL isMouseDown;
    CGImageRef upState;
    CGImageRef downState;
}

@property BOOL isMouseDown;
@property CGImageRef upState;
@property CGImageRef downState;

+ (id) buttonLayerWithUpState:(CGImageRef)upState downState:(CGImageRef)downState;

@end
