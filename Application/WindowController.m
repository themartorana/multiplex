#import "WindowController.h"
#import "MainView.h"

@implementation WindowController

- (void) awakeFromNib
{
    [mainView setContent:movies];
}

@end
