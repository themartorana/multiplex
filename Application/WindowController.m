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
#import "NSDescriptionValueTransformer.h"

#import "StadiumLayoutManager.h"
#import "LinearLayoutManager.h"

#import <QuartzCore/QuartzCore.h>
#import <Sparkle/Sparkle.h>
#import <Toolkit/Toolkit.h>

@interface WindowController (Private)
- (void) openInfoView:(NSNotification*)notification;
@end

@implementation WindowController
@synthesize appManagedObjectContext;

+ (void) initialize
{
    if ([self class] == [WindowController class]) {
        /*  Setup our user defaults.
         */
        [[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
            [NSNumber numberWithInt:24 * 60 * 60], @"SUScheduledCheckInterval",
            kCFBooleanTrue, @"SUEnableAutomaticChecks",
            nil
        ]];
    }
}

- (id) init 
{
    if (self == [super init]) {
        [NSDescriptionValueTransformer registerYourself];
        
        managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Multiplex" ofType:@"mom"]]];
        
        persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:managedObjectModel];
        [persistentStoreCoordinator addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:nil options:nil error:nil];

        engineManagedObjectContext = [[NSManagedObjectContext alloc] init];
        [engineManagedObjectContext setPersistentStoreCoordinator:persistentStoreCoordinator];

        appManagedObjectContext = [[NSManagedObjectContext alloc] init];
        [appManagedObjectContext setPersistentStoreCoordinator:persistentStoreCoordinator];

        NSNotificationCenter* notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter addObserver:self selector:@selector(engineControllerObjectContextDidSave:) name:NSManagedObjectContextDidSaveNotification object:engineManagedObjectContext];
        [notificationCenter addObserver:self selector:@selector(appControllerObjectContextDidSave:) name:NSManagedObjectContextDidSaveNotification object:appManagedObjectContext];
    }
    return self;
}

- (void) engineControllerObjectContextDidSave:(NSNotification*)saveNotification 
{
    @try {
        [appManagedObjectContext mergeChangesFromContextDidSaveNotification:saveNotification];
    } @catch (id exception) {
        NSLog(@"%@", exception);
    }
}

- (void) appControllerObjectContextDidSave:(NSNotification*)saveNotification 
{
    @try {
        [engineManagedObjectContext mergeChangesFromContextDidSaveNotification:saveNotification];
    } @catch (id exception) {
        NSLog(@"%@", exception);
    }
}

- (void) dealloc 
{
    [managedObjectModel release];
    [persistentStoreCoordinator release];
    [appManagedObjectContext release];
    [engineManagedObjectContext release];
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
    
    // Listen for play requests
    NSNotificationCenter* notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self selector:@selector(playDiscRequest:) name:@"MultiplexPlayDisc" object:nil];
    [notificationCenter addObserver:self selector:@selector(openInfoView:) name:@"MultiplexShowMovieDialog" object:nil];
    [notificationCenter addObserver:self selector:@selector(closeInfoView:) name:@"MultiplexCloseMovieDialog" object:nil];
    [notificationCenter addObserver:self selector:@selector(playSelectedMovie:) name:@"MultiplexPlayButtonClicked" object:nil];
    [notificationCenter addObserver:self selector:@selector(toggleFullScreen:) name:@"MultiplexToggleFullScreen" object:nil];
    
    [notificationCenter addObserver:self selector:@selector(mainWindowWillClose:) name:NSWindowWillCloseNotification object:[mainView window]];
    
    engineController = [[EngineController alloc] initWithManagedObjectContext:engineManagedObjectContext];
    
    // Hook up to drawer view
    [drawerView addObserver:self forKeyPath:@"isOpen" options:NSKeyValueObservingOptionNew context:nil];
    
    // Put uservoice button forward
    [userVoiceButton setWantsLayer:YES];
    [[userVoiceButton layer] setZPosition:2000.0];
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

- (void) userVoicePanelDidEnd:(NSPanel*)panel returnCode:(int)returnCode contextInfo:(void*)contextInfo
{
    [panel orderOut:self];
    [userVoiceFeedbackPanel resetFeedbackPage];
}

- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
    if (object == drawerView) {
        if ([@"isOpen" isEqualToString:keyPath]) {
            BOOL isOpen = [(NSNumber*)[object valueForKeyPath:keyPath] boolValue];
            
            if (isOpen) {
                [mainView setFloorLayerLayoutManagerClass:[LinearLayoutManager class]];
            }
            else {
                [mainView setFloorLayerLayoutManagerClass:[StadiumLayoutManager class]];
            }
        }
    }
}

- (void) mainWindowWillClose:(NSNotification*)notification
{
    [NSApp terminate:self];
}

- (IBAction) toggleFullScreen:(id)sender
{
    NSWindow* mainWindow = [sender window];
    
    if ([[mainWindow contentView] isInFullScreenMode]) {
        [[mainWindow contentView] exitFullScreenModeWithOptions:nil];
    }
    else {
        [[mainWindow contentView] enterFullScreenMode:[NSScreen mainScreen] 
                                          withOptions:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:NSFullScreenModeAllScreens]
        ];
    }
}

- (IBAction) switchToStadiumLayoutManager:(id)sender
{
    [mainView setFloorLayerLayoutManagerClass:[StadiumLayoutManager class]];
}

- (IBAction) switchToGridLayoutManager:(id)sender
{
    //[[mainView setFloorLayerLayoutManagerClass:[GridLayoutManager class]];    
}

- (IBAction) switchToLinearLayoutManager:(id)sender
{
    [mainView setFloorLayerLayoutManagerClass:[LinearLayoutManager class]];
}

@end





