#import "ApplicationController.h"
#import "EngineController.h"
#import "MainView.h"
#import "DrawerView.h"
#import "Movie.h"
#import "Disc.h"
#import "Media.h"
#import "MultiplexColorFactory.h"
#import "MovieDetailController.h"
#import "MovieLookupController.h"
#import "UserVoiceFeedbackPanel.h"
#import "NSDescriptionValueTransformer.h"
#import "IsExactlyOneValueTransformer.h"
#import "ApplicationResources.h"

#import "StadiumLayoutManager.h"
#import "LinearLayoutManager.h"

#import "DrawerViewControllerProtocol.h"

#import "MultiplexResourceURLProtocol.h"

#import <QuartzCore/QuartzCore.h>
#import <Sparkle/Sparkle.h>
#import <Toolkit/Toolkit.h>

#import <zlib.h>
#import <mach/mach.h>
#import <mach-o/dyld.h>
#import "Licensing_dylib.c"

#import <Security/Security.h>

@implementation ApplicationController
@synthesize searchQuery;
@synthesize parameters;
@synthesize appManagedObjectContext;
@synthesize selectedMovie;
@synthesize currentDrawerViewController;
@synthesize selectedSegment;

+ (void) initialize
{
    if ([self class] == [ApplicationController class]) {
        /*  Register our value transformers.
         */
        [NSDescriptionValueTransformer registerYourself];
        [IsExactlyOneValueTransformer registerYourself];

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
        
        NSError* error = nil;

        NSFileManager* fileManager = [NSFileManager defaultManager];
        NSString* baseFolder = @"/Library/Application Support/Multiplex";
        NSString* pathToDatabase = [baseFolder stringByAppendingPathComponent:@"Movie.database"];
        BOOL isDirectory = NO;
        if (![fileManager fileExistsAtPath:baseFolder isDirectory:&isDirectory] || !isDirectory) {
            [fileManager removeItemAtPath:baseFolder error:&error];
            if (![fileManager createDirectoryAtPath:baseFolder attributes:nil]) {
                /* TODO: Handle this condition */;
                NSLog(@"no.");
                
                AuthorizationItem myItems[1];
                myItems[0].name = "system.finder.folder.create";
                myItems[0].valueLength = 0;
                myItems[0].value = NULL;
                myItems[0].flags = 0;
                
                AuthorizationRights authSet;
                authSet.count = 1;
                authSet.items = myItems;
                
                AuthorizationFlags authFlags = kAuthorizationFlagDefaults | 
                    kAuthorizationFlagInteractionAllowed |
                    kAuthorizationFlagExtendRights;
                
                AuthorizationRef myAuthorizationRef;
                OSStatus myStatus;
                
                myStatus = AuthorizationCreate(&authSet, 
                                               kAuthorizationEmptyEnvironment, 
                                               authFlags, 
                                               &myAuthorizationRef);
                
                
                // Try something here
                const char* installPath = [baseFolder fileSystemRepresentation];
                char myToolPath[] = "/bin/mkdir";
                char *myArguments[] = { "-m", "777", (char*)installPath, NULL };
                FILE *myCommunicationsPipe = NULL;
                
                authFlags = kAuthorizationFlagDefaults; 
                myStatus = AuthorizationExecuteWithPrivileges(myAuthorizationRef, 
                                                              myToolPath, 
                                                              authFlags, 
                                                              myArguments,
                                                              &myCommunicationsPipe);
                
                AuthorizationFree(myAuthorizationRef, kAuthorizationFlagDestroyRights);
            }
        }

        managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Multiplex" ofType:@"mom"]]];
        persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:managedObjectModel];
        if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:[NSURL fileURLWithPath:pathToDatabase] options:nil error:&error]) {
            [fileManager removeItemAtPath:pathToDatabase error:nil];
            if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:[NSURL fileURLWithPath:pathToDatabase] options:nil error:&error]) {
                [NSException raise:NSStringFromClass([self class]) format:@"Unable to create a fresh database."];
            }
        }
        
        engineManagedObjectContext = [[NSManagedObjectContext alloc] init];
        [engineManagedObjectContext setPersistentStoreCoordinator:persistentStoreCoordinator];
        [engineManagedObjectContext setPropagatesDeletesAtEndOfEvent:NO];
        
        appManagedObjectContext = [[NSManagedObjectContext alloc] init];
        [appManagedObjectContext setPersistentStoreCoordinator:persistentStoreCoordinator];
        [appManagedObjectContext setPropagatesDeletesAtEndOfEvent:NO];

        NSNotificationCenter* notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter addObserver:self selector:@selector(engineControllerObjectContextDidSave:) name:NSManagedObjectContextDidSaveNotification object:engineManagedObjectContext];
        [notificationCenter addObserver:self selector:@selector(appControllerObjectContextDidSave:) name:NSManagedObjectContextDidSaveNotification object:appManagedObjectContext];
        
        // Register our URL handler
        [NSURLProtocol registerClass:[MultiplexResourceURLProtocol class]];
    }
    return self;
}

- (void) engineControllerObjectContextDidSave:(NSNotification*)saveNotification 
{
    [appManagedObjectContext performSelectorOnMainThread:@selector(mergeChangesFromContextDidSaveNotification:) withObject:saveNotification waitUntilDone:NO];
}

- (void) appControllerObjectContextDidSave:(NSNotification*)saveNotification 
{
    [engineManagedObjectContext performSelectorOnMainThread:@selector(mergeChangesFromContextDidSaveNotification:) withObject:saveNotification waitUntilDone:NO];
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

- (void) loadLocalFonts
{
    NSString *fontsFolder;    
    if ((fontsFolder = [[NSBundle mainBundle] resourcePath])) {
        NSURL *fontsURL;
        if ((fontsURL = [NSURL fileURLWithPath:fontsFolder])) {
            FSRef fsRef;
            FSSpec fsSpec;
            CFURLGetFSRef((CFURLRef)fontsURL, &fsRef);
            if (FSGetCatalogInfo(&fsRef, kFSCatInfoNone, NULL, NULL, &fsSpec, 
                                 NULL) == noErr) {
                FMActivateFonts(&fsSpec, NULL, NULL, kFMLocalActivationContext);
            }
        }
    }
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
    [movies addObserver:self forKeyPath:@"selection.self" options:NSKeyValueObservingOptionNew context:nil];
    [drawerView addObserver:self forKeyPath:@"isOpen" options:NSKeyValueObservingOptionNew context:nil];
    
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
    [notificationCenter addObserver:self selector:@selector(closeDrawerView:) name:@"MultiplexCloseDrawerView" object:nil];
    [notificationCenter addObserver:self selector:@selector(playSelectedMovie:) name:@"MultiplexPlayMovie" object:nil];
    [notificationCenter addObserver:self selector:@selector(toggleFullScreen:) name:@"MultiplexToggleFullScreen" object:nil];
    [notificationCenter addObserver:self selector:@selector(openInfoView:) name:@"MultiplexShowMovieDialog" object:nil];
    
    [notificationCenter addObserver:self selector:@selector(refreshInfoFromInternetByUPC:) name:@"MultiplexRefreshMovieInfoFromInternetByUPC" object:nil];
    [notificationCenter addObserver:self selector:@selector(refreshInfoFromInternetByTitle:) name:@"MultiplexRefreshMovieInfoFromInternetByTitle" object:nil];
    
    engineController = [[EngineController alloc] initWithManagedObjectContext:engineManagedObjectContext];
    
    // Put uservoice button forward
    [userVoiceButton setWantsLayer:YES];
    [[userVoiceButton layer] setZPosition:2000.0];
    
    // No discs view
    [noDiscsView setWantsLayer:YES];
    [[noDiscsView layer] setDelegate:self]; 
    
    [self loadLocalFonts];
    NSFont* uniFont = [NSFont fontWithName:@"uni 05_53" size:8.0];
    [licensingAndVersionInfo setFont:uniFont];
    
    // Delayed binding
    // TODO: Rethink this
    [self performSelector:@selector(bindNoMoviesDisplay) withObject:nil afterDelay:7.0];
}

- (void) bindNoMoviesDisplay
{
    //[movies addObserver:self forKeyPath:@"content.@count" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew context:nil];
    [noDiscsView bind:@"hidden" toObject:movies withKeyPath:@"content.@count" options:nil];
}

- (void) applicationDidFinishLaunching:(NSNotification*)notification
{
    [self.window makeKeyAndOrderFront:nil];
    if (!parameters) {
        CIFilter* blurFilter = [CIFilter filterWithName:@"CIGaussianBlur"];
        [blurFilter setDefaults];
        [blurFilter setValue:[NSNumber numberWithDouble:3.0] forKey:@"inputRadius"];
        [[[self window] contentView] layer].filters = [NSArray arrayWithObject:blurFilter];
        
        /*  There was an expiration date in the parameters, and it's 
         *  passed.  Let them know that they should pay up...  in a 
         *  nice way.
         */
        NSAlert* alert = [NSAlert alertWithMessageText:NSLocalizedString(@"This beta of Multiplex has expired.", @"") defaultButton:nil alternateButton:NSLocalizedString(@"No, I'll yell at Dave or Jason", "") otherButton:nil informativeTextWithFormat:NSLocalizedString(@"If you haven't already received a new version to replace this one, go yell at Dave (and/or Jason)... Would you like to check for an update?", @"")];
        [alert setAlertStyle:NSCriticalAlertStyle];
        NSLog(@"%@", self.window);
        [alert beginSheetModalForWindow:[self window] modalDelegate:self didEndSelector:@selector(_licensingAlertDidEnd:returnCode:contextInfo:) contextInfo:nil];
    }
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
                if ([media.isAvailable boolValue] && [media.isLocal boolValue]) {
                    NSWorkspace* workspace = [NSWorkspace sharedWorkspace];
                    NSString* pathToExecutable = [workspace absolutePathForAppBundleWithIdentifier:@"com.apple.DVDPlayer"];
                    [workspace openFile:media.pathToFile withApplication:pathToExecutable];
                    break;
                }
            } 
        }
    }
}

- (void) playSelectedMovie:(NSNotification*)notification
{
    [self setSelectedMovieFromNotificationIfNecessary:notification];
    
    if (selectedMovie) {
        if ([selectedMovie.allDiscs count] == 1) {
            Disc* d = [[selectedMovie.allDiscs allObjects] objectAtIndex:0];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"MultiplexPlayDisc" object:d];
        }
        else if ([selectedMovie.allDiscs count] > 1) {
            [self showMovieDetailAndSelectDiscsTabMovie:selectedMovie];
        }
    }
}

- (void) refreshInfoFromInternetByUPC:(NSNotification*)notification
{
    Movie* m = (Movie*)[notification object];
    
    if (m) {
        [self showMovieLookupForMovie:m byTitle:NO];
    }
}

- (void) refreshInfoFromInternetByTitle:(NSNotification*)notification
{
    Movie* m = (Movie*)[notification object];
    
    if (m) {
        [self showMovieLookupForMovie:m byTitle:YES];
    }
}

- (BOOL) canSwitchDrawerControllers
{
    if (currentDrawerViewController) {
        if ([currentDrawerViewController relinquishControl]) {
            [currentDrawerViewController release];
            currentDrawerViewController = nil;
            
            [mainView resetCurrentlySelectedMovieLayer];
            
            return YES;
        }
        else {
            return NO;
        }
    }

    return YES;
}

- (void) setCurrentDrawerViewController:(DrawerViewControllerProtocol*)protocolObject
{
    if ([self canSwitchDrawerControllers]) {
        currentDrawerViewController = [protocolObject retain];
        [currentDrawerViewController takeControl];        
    }
}

- (void) showMovieDetailForMovie:(Movie*)movie
{
    [movies setSelectedObjects:[NSArray arrayWithObject:movie]];
    if (!movieDetailController) {
        movieDetailController = [[MovieDetailController alloc] initWithApplicationController:self drawerView:drawerView];
    }
    [movieDetailController startWithMovie:movie];
    [self setCurrentDrawerViewController:(DrawerViewControllerProtocol*)movieDetailController];
}

- (void) showMovieDetailAndSelectHomeTabForMovie:(Movie*)movie
{
    [self showMovieDetailForMovie:movie];
    [movieDetailController showHomeTab];
}

- (void) showMovieDetailAndSelectDiscsTabMovie:(Movie*)movie
{
    [self showMovieDetailForMovie:movie];
    [movieDetailController showDiscsTab];
}

- (void) showMovieLookupForMovie:(Movie*)movie byTitle:(BOOL)byTitle
{
    [movies setSelectedObjects:[NSArray arrayWithObject:movie]];
    if (!movieLookupController) {
        movieLookupController = [[MovieLookupController alloc] initWithApplicationController:self drawerView:drawerView];
    }
    [movieLookupController startWithMovie:movie];
    [self setCurrentDrawerViewController:(DrawerViewControllerProtocol*)movieLookupController];
    
    if (byTitle) {
        [movieLookupController skipToTitleEntry:nil];
    }
}

- (void) closeDrawerView:(NSNotification*)notification
{
    if ([self canSwitchDrawerControllers]) {
        [drawerView closeDrawer];
        [[self window] makeFirstResponder:searchField];        
    }
}

- (void) openInfoView:(NSNotification*)notification
{
    [self setSelectedMovieFromNotificationIfNecessary:notification];
    
    [drawerView openDrawer];
    [movieDetailController showHomeTab];
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

- (void) setSelectedMovieFromNotificationIfNecessary:(NSNotification*)n
{
    id obj = [n object];
    if (obj && [obj isKindOfClass:[NSManagedObject class]]) {
        NSEntityDescription* movieEntity = [NSEntityDescription entityForName:@"Movie" inManagedObjectContext:appManagedObjectContext];
    
        if ([[(NSManagedObject*)obj entity] isKindOfEntity:movieEntity]) {
            // Select the movie if it's a movie
            [movies setSelectedObjects:[NSArray arrayWithObject:obj]];
        }
    }
}

- (void) userVoicePanelDidEnd:(NSPanel*)panel returnCode:(int)returnCode contextInfo:(void*)contextInfo
{
    [panel orderOut:self];
    [userVoiceFeedbackPanel resetFeedbackPage];
}

- (NSArray*) feedParametersForUpdater:(SUUpdater*)updater sendingSystemProfile:(BOOL)sendingProfile;
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
    if (object == drawerView) {
        if ([@"isOpen" isEqualToString:keyPath]) {
            BOOL isOpen = [[object valueForKeyPath:keyPath] boolValue];
            Class cLayoutManager;
            if (isOpen) {
                
                cLayoutManager = NSClassFromString([[NSUserDefaults standardUserDefaults] objectForKey:kMultiplexDrawerIsOpenLayoutManagerClass]);
                if (!cLayoutManager)
                {
                    cLayoutManager = [LinearLayoutManager class];
                }
                [mainView setFloorLayerLayoutManagerClass:cLayoutManager];
                
                if ([selectedMovie.gtin length] > 0 || selectedMovie.metadataAcceptedDate != nil) {
                    [self showMovieDetailForMovie:selectedMovie];
                } else if (selectedMovie) {
                    [self showMovieLookupForMovie:selectedMovie byTitle:NO];
                } else {
                    [drawerView setContentView:noMovieSelectedView];
                }
                [[self window] makeFirstResponder:drawerView];
            } else {
                cLayoutManager = NSClassFromString([[NSUserDefaults standardUserDefaults] objectForKey:kMultiplexDrawerIsClosedLayoutManagerClass]);
                if (!cLayoutManager)
                {
                    cLayoutManager = [StadiumLayoutManager class];
                }
                [mainView setFloorLayerLayoutManagerClass:cLayoutManager];
                
                [drawerView setContentView:nil];
                [[self window] makeFirstResponder:searchField];
            }
            
            if (cLayoutManager == [StadiumLayoutManager class]) {
                [self setSelectedSegment:0];
            }
            else if (cLayoutManager == [LinearLayoutManager class]) {
                [self setSelectedSegment:1];
            }
        }
    } else if (object == movies) {
        if ([@"selection.self" isEqualToString:keyPath]) {
            Movie* _selectedMovie = [movies valueForKeyPath:keyPath];
            if (_selectedMovie == NSNoSelectionMarker) {
                _selectedMovie = nil;
            }
            if (selectedMovie != _selectedMovie) {
                [self setSelectedMovie:_selectedMovie];
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
    }    
}

- (void) setSearchQuery:(NSString*)_searchQuery
{
    if (_searchQuery != searchQuery) {
        [searchQuery release];
        searchQuery = [_searchQuery retain];
        if (searchQuery) {
            movies.filterPredicate = [NSPredicate predicateWithFormat:@"(title beginswith[c] %@) or (title contains[c] %@)", searchQuery, [@" " stringByAppendingString:searchQuery]];
        } else {
            movies.filterPredicate = nil;
        }
        NSLog(@"%@", movies.filterPredicate);
    }
}

- (void) _licensingAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    if (NSAlertDefaultReturn == returnCode) {
        [[SUUpdater sharedUpdater] checkForUpdates:self];
    }
}

- (IBAction) toggleFullScreen:(id)sender
{
    NSWindow* mainWindow = [sender window];
    
    if ([[mainWindow contentView] isInFullScreenMode]) {
        [[mainWindow contentView] exitFullScreenModeWithOptions:nil];
        [windowResizeThumb setHidden:NO];
        viewInFullScreen = nil;
        
        //[fullScreenButton setImage:[NSImage imageNamed:]];
    }
    else {
        [[mainWindow contentView] enterFullScreenMode:[NSScreen mainScreen] 
                                          withOptions:nil]; //[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:NSFullScreenModeAllScreens]];
        viewInFullScreen = [mainWindow contentView];
        [windowResizeThumb setHidden:YES];
        
        //[fullScreenButton sh setImage:[NSImage imageNamed:@"collapse-screen"]];
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

- (void) windowDidResignMain:(NSNotification*)notification
{
    NSLog(@"resigned");
    if (viewInFullScreen && [viewInFullScreen isInFullScreenMode]) {
        [self toggleFullScreen:viewInFullScreen];
    }
}

- (void) setSelectedSegment:(int)sel
{
    selectedSegment = sel;
    
    if (sel == 0) {
        if (mainView.floorLayerLayoutManagerClass != [StadiumLayoutManager class]) {
            [self switchToStadiumLayoutManager:nil];
        }
    }
    else if (sel == 1) {
        if (mainView.floorLayerLayoutManagerClass != [LinearLayoutManager class]) {
            [self switchToLinearLayoutManager:nil];
        }
    }
}

@end






