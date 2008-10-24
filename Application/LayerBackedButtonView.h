#import <Cocoa/Cocoa.h>

@class ButtonLayer;

@interface LayerBackedButtonView : NSView {
    CALayer* backingLayer;
    ButtonLayer* buttonLayer;
    NSString* notificationNameToPost;
}

@property (retain) NSString* notificationNameToPost;

- (void) setButtonLayerButtonWithUpState:(CGImageRef)buttonUp andDownState:(CGImageRef)buttonDown;

@end
