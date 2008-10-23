#import "WindowController.h"
#import "EngineController.h"
#import "MainView.h"
#import "DrawerView.h"
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
@synthesize managedObjectContext;

- (id) init 
{
    if (self == [super init]) {
        managedObjectModel = [[NSManagedObjectModel mergedModelFromBundles:nil] retain];
        
        persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:managedObjectModel];
        [persistentStoreCoordinator addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:nil options:nil error:nil];
        
        managedObjectContext = [[NSManagedObjectContext alloc] init];
        [managedObjectContext setPersistentStoreCoordinator:persistentStoreCoordinator];
    }
    return self;
}

- (void) dealloc 
{
    [managedObjectModel release];
    [persistentStoreCoordinator release];
    [managedObjectContext release];
    [engineController release];
    [super dealloc];
}

- (void) awakeFromNib
{
    NSView* contentView = self.window.contentView;
    contentView.layer.backgroundColor = [MultiplexColorFactory black];
    
    /*  Sort the movies alphabetically
     */
    NSSortDescriptor* sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES];
    [movies setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    [sortDescriptor release];

    /*  Give the MainView movies to play with.
     */
    [mainView setContent:movies];
        
    [infoPaneFormController bind:@"movie" toObject:movies withKeyPath:@"selection.self" options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:NSAllowsNullArgumentBindingOption]];
    
    movieDesc = [[NSEntityDescription entityForName:@"Movie" inManagedObjectContext:managedObjectContext] retain];
    
    // Listen for play requests
    NSNotificationCenter* notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self selector:@selector(playDiscRequest:) name:@"MultiplexPlayDisc" object:nil];
    [notificationCenter addObserver:self selector:@selector(openInfoView:) name:@"MultiplexShowMovieDialog" object:nil];
    [notificationCenter addObserver:self selector:@selector(closeInfoView:) name:@"MultiplexCloseMovieDialog" object:nil];
    [notificationCenter addObserver:self selector:@selector(playSelectedMovie:) name:@"MultiplexPlayButtonClicked" object:nil];
#if 0
    [notificationCenter addObserver:self selector:@selector(_coreDataDidSaveNotification:) name:NSManagedObjectContextDidSaveNotification object:nil];
#endif
    
    engineController = [[EngineController alloc] initWithManagedObjectContext:managedObjectContext];
}

- (void) applicationDidFinishLaunching:(NSNotification*)notification
{
    [self.window makeKeyAndOrderFront:nil];
}

- (void) applicationWillTerminate:(NSNotification*)notification
{
    [engineController shutdown];
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

- (void) openInfoView:(NSNotification*)notification
{
    [drawerView openDrawer];
    [[self window] makeFirstResponder:infoPaneView];
}

- (void) closeInfoView:(NSNotification*)notification
{
    [drawerView closeDrawer];
    [[self window] makeFirstResponder:searchView];
}

- (IBAction) showUserVoiceFeedbackSheet:(id)sender
{
    [userVoiceFeedbackPanel setFrame:[self.window.contentView frame] display:YES];
        
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

#if 0
- (void) _coreDataDidSaveNotification:(NSNotification*)notification
{
    NSDictionary* userInfo = [notification userInfo];
    
    NSMutableArray* insertedMovies = nil;
    for (NSManagedObject* object in [userInfo objectForKey:NSInsertedObjectsKey]) {
        if ([object entity] == movieDesc) {
            if (!insertedMovies) {
                insertedMovies = [NSMutableArray array];
            }
            [insertedMovies addObject:object];
        }
    }
    if (insertedMovies) {
        [movies addObjects:insertedMovies];
    }
    
    NSMutableArray* deletedMovies = nil;
    for (NSManagedObject* object in [userInfo objectForKey:NSDeletedObjectsKey]) {
        if ([object entity] == movieDesc) {
            if (!deletedMovies) {
                deletedMovies = [NSMutableArray array];
            }
            [deletedMovies addObject:object];
        }
    }
    if (deletedMovies) {
        @try {
            [movies removeObjects:deletedMovies];
        }
        @catch (NSException* exception) {
            NSLog(@"%@", exception);
        }
    }    
}
#endif

@end





