#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

@class PlayButtonLayer;
@class InfoButtonLayer;
@class CloseButtonLayer;

@interface InfoPaneView : NSView {
    InfoButtonLayer* infoButtonLayer;
    CloseButtonLayer* closeButtonLayer;
}

@end
