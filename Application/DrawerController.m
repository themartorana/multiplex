#import "DrawerController.h"
#import "DrawerView.h"
#import "Movie.h"

@interface DrawerController (Private)
- (void) changeDrawerView:(BOOL)isOpen;
@end


@implementation DrawerController

- (void) awakeFromNib
{
    [self bind:@"selectedMovie" toObject:movies withKeyPath:@"selection.self" options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:NSAllowsNullArgumentBindingOption]];
    [drawerView addObserver:self forKeyPath:@"isOpen" options:NSKeyValueObservingOptionNew context:nil];
}

- (void) dealloc
{
    [selectedMovie release];
    [super dealloc];
}

- (void) setSelectedMovie:(Movie*)m
{   
    if (selectedMovie) {
        [selectedMovie release];
        selectedMovie = nil;
    }
    
    selectedMovie = [m retain];
    
    if (drawerView.isOpen) {
        [self changeDrawerView:YES];
    }
}

- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
    if (object == drawerView) {
        if ([@"isOpen" isEqualToString:keyPath]) {
            BOOL isOpen = [(NSNumber*)[object valueForKeyPath:keyPath] boolValue];
            [self changeDrawerView:isOpen];
        }
    }
}

- (void) changeDrawerView:(BOOL)isOpen
{
  if (isOpen) {
        // Put in the appropriate view
        if (selectedMovie) {
            if (selectedMovie.gtin && ![selectedMovie.gtin isEqualToString:@""]) {
                [drawerView setContentView:movieInfoView];
            }
            else {
                [drawerView setContentView:enterUPCView];
            }
        }
        else {
            [drawerView setContentView:noMovieSelectedView];
        }
    }
    else {
        [drawerView setContentView:nil];
    }
}

- (IBAction) skipEnterUPC:(id)sender
{
    [drawerView setContentView:movieInfoView];
}

@end
