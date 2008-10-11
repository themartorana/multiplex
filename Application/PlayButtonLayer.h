#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

@interface PlayButtonLayer : CALayer {
    CGImageRef playButtonImage;
    CGImageRef playButtonImageDown;
    
    BOOL isMouseDown;
}

@property BOOL isMouseDown;

@end
