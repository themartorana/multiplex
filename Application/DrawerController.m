#import "DrawerController.h"
#import "DrawerView.h"
#import "Movie.h"

#import "InfoPaneFormController.h"

static NSString* const kAmazonAccessKey = @"01Y2NSCMDJ3VJXTCBTR2";

@interface DrawerController (Private)
- (void) changeDrawerView:(BOOL)isOpen;
- (void) showResultAtIndex:(int)index;
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

- (void) setSelectedMovie:(Movie*)_selectedMovie
{   
    if (selectedMovie != _selectedMovie) {
        [selectedMovie release];
        selectedMovie = [_selectedMovie retain];
        [self changeDrawerView:drawerView.isOpen];
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
    if (!isOpen) {
        [drawerView setContentView:nil];
    } 
    else if ([selectedMovie.gtin length] > 0 || selectedMovie.metadataAcceptedDate != nil) {
        [drawerView setContentView:infoPaneView];
    } 
    else if (selectedMovie) {
        [infoLookupController beginLookupForMovie:selectedMovie];
    } 
    else {
        [drawerView setContentView:noMovieSelectedView];
    }
}

- (void) showInfoPanelAndSelectHomeTab:(id)sender
{
    [drawerView setContentView:infoPaneView];
    [formController showHomeTab];
}

@end
