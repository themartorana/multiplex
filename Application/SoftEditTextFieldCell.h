#import <Cocoa/Cocoa.h>
@class CALayer;

@interface SoftEditTextFieldCell : NSTextFieldCell {
    CALayer* backgroundLayer;
    NSTextView* fieldEditor;
}

@end
