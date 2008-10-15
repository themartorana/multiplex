#import "InfoPaneHostingView.h"
#import <QuartzCore/QuartzCore.h>
#import "Movie.h"
#import "CGColorFactory.h"

@implementation InfoPaneHostingView

- (void) awakeFromNib 
{
    [self setWantsLayer:YES];
    [self layer].backgroundColor = [CGColorFactory blackHalfTransparent];
}

@end

