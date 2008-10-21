#import "WindowController.h"
#import "MainView.h"
#import "Movie.h"
#import "Disc.h"
#import "Media.h"
#import "MultiplexColorFactory.h"
#import "InfoPaneFormController.h"
#import "UserVoiceFeedbackPanel.h"

#import <QuartzCore/QuartzCore.h>

@interface WindowController (Private)
- (void) openInfoView:(NSNotification*)notification;
@end

@implementation WindowController

- (void) awakeFromNib
{
    // TODO: Move this somewhere appropriate!!
    [infoPaneView setHidden:YES];
    [infoPaneView setFrame:[[[mainView window] contentView] frame]];
    [[[mainView window] contentView] addSubview:infoPaneView positioned:NSWindowAbove relativeTo:nil];
    
    NSView* contentView = self.window.contentView;
    contentView.wantsLayer = YES;
    
    CALayer* background = contentView.layer;
    
    /*  Sort the movies alphabetically
     */
    NSSortDescriptor* sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES];
    [movies setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    [sortDescriptor release];

    background.backgroundColor = [MultiplexColorFactory black];
    
    [mainView setContent:movies];
        
    NSDictionary* options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:NSAllowsNullArgumentBindingOption];
    [infoPaneFormController bind:@"selectedMovie" toObject:movies withKeyPath:@"selection.self" options:options];
    
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
                    break;
                }
            } 
        }
    }
}

- (void) playSelectedMovie:(NSNotification*)notification
{
    Movie* movie = nil;
    
    if ([notification object] && [[notification object] isKindOfClass:[Movie class]]) {
        movie = (Movie*)[notification object];
    }
    else {
        movie = (Movie*)[[movies selectedObjects] objectAtIndex:0];
    }
    
    if (movie && [movie.allDiscs count] == 1) {
        Disc* d = (Disc*)[[movie.allDiscs allObjects] objectAtIndex:0];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"MultiplexPlayDisc" object:d];
    } else if (movie && [movie.allDiscs count] > 1) {
        // We want to show the dialog
        [self openInfoView:nil];
        [infoPaneFormController showDiscsTab];
    }
}

- (IBAction) toggleDrawerView:(id)sender
{
    [sender setFrameCenterRotation:M_PI/4.0];
}


- (void) openInfoView:(NSNotification*)notification
{
    [CATransaction begin];
    [CATransaction setValue:[NSNumber numberWithDouble:0.25] forKey:kCATransactionAnimationDuration];
    {
        CIFilter* blurFilter = [CIFilter filterWithName:@"CIGaussianBlur"];
        [blurFilter setDefaults];
        [blurFilter setValue:[NSNumber numberWithInt:2.0] forKey:@"inputRadius"];
        [infoPaneFormController showHomeTab]; 
        
        [mainView setHoveredMovie:nil];
        [[searchView animator] setHidden:YES];
        [[mainView animator] setContentFilters:[NSArray arrayWithObject:blurFilter]];
        [[infoPaneView animator] setHidden:NO];
    }
    [CATransaction commit];

    [[self window] makeFirstResponder:infoPaneView];
}

- (void) closeInfoView:(NSNotification*)notification
{
    [CATransaction begin];
    [CATransaction setValue:[NSNumber numberWithDouble:0.25] forKey:kCATransactionAnimationDuration];
    {
        [[searchView animator] setHidden:NO];
        [[mainView animator] setContentFilters:nil];
        [[infoPaneView animator] setHidden:YES];
    }
    [CATransaction commit];
    
    [[self window] makeFirstResponder:searchView];
}

- (IBAction) showUserVoiceFeedbackSheet:(id)sender
{
    [userVoiceFeedbackPanel setFrame:[mainView frame] display:YES];
        
    [NSApp beginSheet:(NSWindow*)userVoiceFeedbackPanel 
       modalForWindow:[mainView window] 
        modalDelegate:self 
       didEndSelector:@selector(userVoicePanelDidEnd:returnCode:contextInfo:) 
          contextInfo:nil];
}

- (void)userVoicePanelDidEnd:(NSPanel*)panel returnCode:(int)returnCode contextInfo:(void*)contextInfo
{
    [panel orderOut:self];
    [userVoiceFeedbackPanel resetFeedbackPage];
}

@end





