#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

@class ButtonLayer;

@interface InfoPaneView : NSView {
    ButtonLayer* infoButtonLayer;
    ButtonLayer* closeButtonLayer;
}

@end
