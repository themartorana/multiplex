#import "NoDiscsView.h"
#import "ApplicationResources.h"
#import "MultiplexColorFactory.h"

#import <QuartzCore/QuartzCore.h>

@implementation NoDiscsView

- (void) awakeFromNib
{
    [self setWantsLayer:YES];
    
    CALayer* layer = [self layer];
    
    layer.backgroundColor = [MultiplexColorFactory drawerBackgroundPattern];
    layer.borderColor = [MultiplexColorFactory white];
    layer.borderWidth = 2.0;
    layer.cornerRadius = 10.0;
}

@end
