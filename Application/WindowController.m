#import "WindowController.h"
#import "MainView.h"
#import <QuartzCore/QuartzCore.h>
#import "Movie.h"
#import "Disc.h"
#import "Media.h"
#import "HoverTitleView.h"
#import "InfoPaneHostingView.h"

@implementation WindowController

- (void) awakeFromNib
{
    // TODO: Move this somewhere appropriate!!
    [infoPaneHostingView setHidden:YES];
    [infoPaneHostingView setFrame:[[[mainView window] contentView] frame]];
    [[[mainView window] contentView] addSubview:infoPaneHostingView];
    
    NSView* contentView = self.window.contentView;
    contentView.wantsLayer = YES;
    
    CALayer* background = contentView.layer;
    background.backgroundColor = CGColorCreateGenericRGB(0.0, 0.0, 0.0, 1.0);

    /*  Sort the movies alphabetically
     */
    NSSortDescriptor* sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES];
    [movies setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    [sortDescriptor release];

    [mainView setContent:movies];
        
    // Do some bindings
    [basicInfoView bind:@"hoveredMovie" toObject:mainView withKeyPath:@"hoveredMovie" options:nil];
    
    [infoPaneFormController bind:@"selectedMovies" toObject:movies withKeyPath:@"selectedObjects" options:nil];
    
    // Listen for play requests
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playDiscRequest:) name:@"MultiplexPlayDisc" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(openInfoView:) name:@"MultiplexShowMovieDialog" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(closeInfoView:) name:@"MultiplexCloseMovieDialog" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playSelectedMovie:) name:@"MultiplexPlayButtonClicked" object:nil];
}

- (void) playDiscRequest:(NSNotification*)notification
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

- (void) playSelectedMovie:(NSNotification*)notification
{
    Movie* movie = (Movie*)[[movies selectedObjects] objectAtIndex:0];
    
    if ([movie.allDiscs count] == 1) {
        Disc* d = (Disc*)[[movie.allDiscs allObjects] objectAtIndex:0];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"MultiplexPlayDisc" object:d];
    }
    else if ([movie.allDiscs count] > 1) {
        // We want to show the dialog
        [infoPaneHostingView setHidden:NO];    
    }
}

- (void) openInfoView:(NSNotification*)notification
{
    [mainView pauseTracking];
    
    /*
    NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys:
                         infoPaneHostingView, NSViewAnimationTargetKey,
                         NSViewAnimationFadeInEffect, NSViewAnimationEffectKey,
                         nil];
    
    NSViewAnimation* anim = [[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObject:dict]];
    [anim setDuration:1.0];
    [anim setAnimationCurve:NSAnimationEaseIn];
    [anim startAnimation];
    [anim release];
    */
    
    /*
    CIFilter* blurFilter = [CIFilter filterWithName:@"CIBoxBlur"];
    [blurFilter setDefaults];
    [blurFilter setValue:[NSNumber numberWithInt:4.0] forKey:@"inputRadius"];
    [[infoPaneHostingView layer] setBackgroundFilters:[NSArray arrayWithObject:blurFilter]];
    */
     
    [infoPaneHostingView setHidden:NO];
}

- (void) closeInfoView:(NSNotification*)notification
{
    [mainView resumeTracking];
    
    /*
    NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys:
                          infoPaneHostingView, NSViewAnimationTargetKey,
                          NSViewAnimationFadeOutEffect, NSViewAnimationEffectKey,
                          nil];
    
    NSViewAnimation* anim = [[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObject:dict]];
    [anim setDuration:1.0];
    [anim setAnimationCurve:NSAnimationEaseIn];
    [anim startAnimation];
    [anim release];
    */
    
    [infoPaneHostingView setHidden:YES];
    [[infoPaneHostingView layer] setBackgroundFilters:nil];
}

@end





