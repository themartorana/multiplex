#import "WindowController.h"
#import "MainView.h"
#import <QuartzCore/QuartzCore.h>

@implementation WindowController

- (void) awakeFromNib
{
    NSView* contentView = self.window.contentView;
    contentView.wantsLayer = YES;
    CALayer* background = contentView.layer;
    background.backgroundColor = CGColorCreateGenericRGB(0.0, 0.0, 0.0, 1.0);
    
    [mainView setContent:movies];
}

@end
