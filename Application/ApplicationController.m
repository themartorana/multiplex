#import "ApplicationController.h"
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
#import "ApplicationResources.h"

#import "StadiumLayoutManager.h"
#import "LinearLayoutManager.h"

#import <QuartzCore/QuartzCore.h>
#import <Sparkle/Sparkle.h>
#import <Toolkit/Toolkit.h>

#import <zlib.h>
#import <mach/mach.h>
#import <mach-o/dyld.h>
#import "Licensing_dylib.c"

@interface ApplicationController (Private)
- (void) openInfoView:(NSNotification*)notification;
@end

@implementation ApplicationController
@synthesize parameters;
@synthesize appManagedObjectContext;

+ (void) initialize
{
    if ([self class] == [ApplicationController class]) {
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

    /*  Setup Bindings & Observations.
     */
    [self addObserver:self forKeyPath:@"parameters" options:0 context:nil];
    [infoPaneFormController bind:@"movie" toObject:movies withKeyPath:@"selection.self" options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:NSAllowsNullArgumentBindingOption]];
    
    /*  Do the licensing stuff.
     */
    void* dylib = nil;
    if (0 == vm_allocate(mach_task_self(), (vm_address_t*)&dylib, LICENSING_DYLIB_LEN_UNCOMPRESSED, VM_FLAGS_ANYWHERE)) {
        uLongf dylibLength = LICENSING_DYLIB_LEN_UNCOMPRESSED;
        uncompress(dylib, &dylibLength, LICENSING_DYLIB, LICENSING_DYLIB_LEN);
        NSObjectFileImage ofi = 0;
        NSObjectFileImageReturnCode dyldError = NSCreateObjectFileImageFromMemory(dylib, dylibLength, &ofi);
        if (dyldError == NSObjectFileImageSuccess) {
            char moduleName[] = { 'L', 'i', 'c', 'e', 'n', 's', 'i', 'n', 'g', '.', 'd', 'y', 'l', 'i', 'b', 0 };
            NSModule module = NSLinkModule(ofi, moduleName, NSLINKMODULE_OPTION_BINDNOW);
            char symbolName[] = { '_', 'l', 'o', 'a', 'd', 'P', 'a', 'r', 'a', 'm', 'e', 't', 'e', 'r', 's', 0 };
            CFDictionaryRef (*loadParameters)() = NSAddressOfSymbol(NSLookupSymbolInModule(module, symbolName));
            [self performSelectorOnMainThread:@selector(setParameters:) withObject:(NSDictionary*)loadParameters() waitUntilDone:NO];
        }
    }
    
    // Listen for play requests
    NSNotificationCenter* notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self selector:@selector(playDiscRequest:) name:@"MultiplexPlayDisc" object:nil];
    [notificationCenter addObserver:self selector:@selector(openInfoView:) name:@"MultiplexShowMovieDialog" object:nil];
    [notificationCenter addObserver:self selector:@selector(closeInfoView:) name:@"MultiplexCloseMovieDialog" object:nil];
    [notificationCenter addObserver:self selector:@selector(playSelectedMovie:) name:@"MultiplexPlayButtonClicked" object:nil];
    [notificationCenter addObserver:self selector:@selector(toggleFullScreen:) name:@"MultiplexToggleFullScreen" object:nil];
    
    engineController = [[EngineController alloc] initWithManagedObjectContext:engineManagedObjectContext];
    
    // Hook up to drawer view
    [drawerView addObserver:self forKeyPath:@"isOpen" options:NSKeyValueObservingOptionNew context:nil];
    
    // Put uservoice button forward
    [userVoiceButton setWantsLayer:YES];
    [[userVoiceButton layer] setZPosition:2000.0];
    
    // No discs view
    [noDiscsView setWantsLayer:YES];
    [[noDiscsView layer] setDelegate:self]; 
    
    // Delayed binding
    // TODO: Rethink this
    [self performSelector:@selector(bindNoMoviesDisplay) withObject:nil afterDelay:7.0];
}

- (void) bindNoMoviesDisplay
{
    [movies addObserver:self forKeyPath:@"content.@count" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew context:nil];
}

- (void) applicationDidFinishLaunching:(NSNotification*)notification
{
    [self.window makeKeyAndOrderFront:nil];
}

- (void) applicationWillTerminate:(NSNotification*)notification
{
    [[self window] close];
    [engineController shutdown];
}

- (BOOL) applicationShouldHandleReopen:(NSApplication*)theApplication hasVisibleWindows:(BOOL)flag
{
    [[self window] makeKeyAndOrderFront:nil];
    return NO;
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

- (IBAction) checkForUpdates:(id)sender
{
    [[SUUpdater sharedUpdater] checkForUpdates:sender];
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

- (NSArray *)feedParametersForUpdater:(SUUpdater *)updater sendingSystemProfile:(BOOL)sendingProfile;
{
    NSMutableArray* pairs = [NSMutableArray array];
    for (NSString* key in parameters) {
        [pairs addObject:
            [NSDictionary dictionaryWithObjectsAndKeys:
                key, @"key",
                [parameters objectForKey:key], @"value",
                nil
             ]
        ];
    }
    return pairs;
}

- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
    if (object == movies) {
        BOOL toSet = [(NSNumber*)[movies valueForKeyPath:keyPath] boolValue];
        if (!toSet == [noDiscsView isHidden]) {
            [[noDiscsView animator] setHidden:toSet];
        }
    }
    else if (object == drawerView) {
        if ([@"isOpen" isEqualToString:keyPath]) {
            BOOL isOpen = [(NSNumber*)[object valueForKeyPath:keyPath] boolValue];
            
            if (isOpen) {
                [mainView setFloorLayerLayoutManagerClass:[LinearLayoutManager class]];
            }
            else {
                [mainView setFloorLayerLayoutManagerClass:[StadiumLayoutManager class]];
            }
        }
    } else if ([keyPath isEqual:@"parameters"]) {
        NSLog(@"%@", parameters);
        if (nil != parameters) {
            if ([parameters objectForKey:@"Expires"]) {
                NSTimeInterval timeRemainingForTrial = [[NSDate dateWithString:[parameters objectForKey:@"Expires"]] timeIntervalSinceDate:[NSDate date]];
                NSString* text = nil;
                if (timeRemainingForTrial < 0) {
                    text = [NSString stringWithFormat:NSLocalizedString(@"Trial Expired", @"")];
                } else if (timeRemainingForTrial < (24 * 60 * 60)) {
                    text = [NSString stringWithFormat:NSLocalizedString(@"Expires Today", @"")];
                } else {
                    text = [NSString stringWithFormat:NSLocalizedString(@"%d days remaining", @""), (int)(timeRemainingForTrial / (24 * 60 * 60)) + 1];
                }
                [licensingAndVersionInfo setStringValue:[NSString stringWithFormat:@"%@ - %@", text, [[NSBundle mainBundle] version]]];
            } else {
                [licensingAndVersionInfo setStringValue:[NSString stringWithFormat:@"Property of %@ - %@", [parameters objectForKey:@"Name"], [[NSBundle mainBundle] version]]];
            }
        }
        SUUpdater* updater = [SUUpdater sharedUpdater];
        [updater setDelegate:self];
        if (!parameters) {
            [updater checkForUpdates:self];
            CIFilter* blurFilter = [CIFilter filterWithName:@"CIGaussianBlur"];
            [blurFilter setDefaults];
            [blurFilter setValue:[NSNumber numberWithDouble:3.0] forKey:@"inputRadius"];
            [[[self window] contentView] layer].filters = [NSArray arrayWithObject:blurFilter];
        }
    }    
}

- (IBAction) toggleFullScreen:(id)sender
{
    NSWindow* mainWindow = [sender window];
    
    if ([[mainWindow contentView] isInFullScreenMode]) {
        [[mainWindow contentView] exitFullScreenModeWithOptions:nil];
        [windowResizeThumb setHidden:NO];
    }
    else {
        [[mainWindow contentView] enterFullScreenMode:[NSScreen mainScreen] 
                                          withOptions:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:NSFullScreenModeAllScreens]
        ];
        [windowResizeThumb setHidden:YES];
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





