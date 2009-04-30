#import "IndeterminateProgressIndicatorView.h"
#import "IndeterminateProgressIndicatorLayer.h"
#import <QuartzCore/QuartzCore.h>

@implementation IndeterminateProgressIndicatorView

- (void) awakeFromNib
{
    progressLayer = [IndeterminateProgressIndicatorLayer layer];
    progressLayer.frame = NSRectToCGRect(self.bounds);
    [self setWantsLayer:YES];
    [[self layer] addSublayer:progressLayer];
}

@end
