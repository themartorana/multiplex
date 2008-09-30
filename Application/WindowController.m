#import "WindowController.h"
#import "MainView.h"
#import <QuartzCore/QuartzCore.h>
#import "Movie.h"
#import "InfoView.h"

@implementation WindowController

- (void) awakeFromNib
{
    NSView* contentView = self.window.contentView;
    contentView.wantsLayer = YES;
    
    CALayer* background = contentView.layer;
    background.backgroundColor = CGColorCreateGenericRGB(0.0, 0.0, 0.0, 1.0);
    
    [mainView setContent:movies];
    
    // Do some bindings
    [infoView bind:@"selectedMovies" toObject:movies withKeyPath:@"selectedObjects" options:nil];
    [infoView bind:@"hoveredMovie" toObject:mainView withKeyPath:@"hoveredMovie" options:nil];
}

@end
