#import <Cocoa/Cocoa.h>

@class IndeterminateProgressIndicatorLayer;

@interface StartupSpinnerView : NSView {
    IndeterminateProgressIndicatorLayer* progressLayer;
    CALayer* backingLayer;
}

@end
