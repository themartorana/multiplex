#import "WindowController.h"
#import "MainView.h"
#import <QuartzCore/QuartzCore.h>
#import "Movie.h"
#import "BasicInfoView.h"

@implementation WindowController

- (void) awakeFromNib
{
    NSView* contentView = self.window.contentView;
    contentView.wantsLayer = YES;
    
    CALayer* background = contentView.layer;
    background.backgroundColor = CGColorCreateGenericRGB(0.0, 0.0, 0.0, 1.0);
    
    [mainView setContent:movies];
    
    // Do some bindings
    [basicInfoView bind:@"selectedMovies" toObject:movies withKeyPath:@"selectedObjects" options:nil];
    [basicInfoView bind:@"hoveredMovie" toObject:mainView withKeyPath:@"hoveredMovie" options:nil];
    
    [infoPaneFormController bind:@"selectedMovies" toObject:movies withKeyPath:@"selectedObjects" options:nil];
}

@end
