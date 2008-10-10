#import "WindowController.h"
#import "MainView.h"
#import <QuartzCore/QuartzCore.h>
#import "Movie.h"
#import "Disc.h"
#import "Media.h"
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
    
    // Listen for play requests
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playMovieRequest:) name:@"MultiplexPlayDisc" object:nil];
}

- (void) playMovieRequest:(NSNotification*)notification
{
    if ([notification object]) {
        Disc* d = (Disc*)[notification object];
        NSArray* allMedia = [d.allMedia allObjects];
        
        if ([allMedia count] > 0) {
            for (Media* media in allMedia) {
                if ([media.isAvailable boolValue]) {
                    // Play
                    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:media.url]];
                }
            } 
        }
    }
}

@end
