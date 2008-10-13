#import "InfoPaneHostingView.h"
#import <QuartzCore/QuartzCore.h>
#import "Movie.h"


@implementation InfoPaneHostingView

- (void) awakeFromNib 
{
    [self setWantsLayer:YES];
    [self layer].backgroundColor = CGColorCreateGenericRGB(0.0, 0.0, 0.0, 0.5);
}

@end

