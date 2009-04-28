#import "ApplicationController.h"
#import "EngineController.h"
#import "MainView.h"
#import "DrawerView.h"
#import "Movie.h"
#import "Disc.h"
#import "Media.h"
#import "MovieURL.h"
#import "MultiplexColorFactory.h"
#import "MovieDetailController.h"
#import "MovieLookupController.h"
#import "UserVoiceFeedbackPanel.h"
#import "NSDescriptionValueTransformer.h"
#import "IsExactlyOneValueTransformer.h"
#import "ApplicationResources.h"
#import "MainWindowContentView.h"

#import "StadiumLayoutManager.h"
#import "LinearLayoutManager.h"

#import "DrawerViewControllerProtocol.h"
#import "PreferencesWindowController.h"

#import "MultiplexResourceURLProtocol.h"

#import "MAAttachedWindow.h"
#import "ZoomableWindow.h"
#import "DeleteConfirmationPanel.h"

#import <QuartzCore/QuartzCore.h>
#import <Sparkle/Sparkle.h>
#import <Toolkit/Toolkit.h>

#import <zlib.h>
#import <mach/mach.h>
#import <mach-o/dyld.h>
#import "Licensing_dylib.c"

#import <Security/Security.h>

static CFStringRef kMDItemMultiplexNonDVDFingerprint = (CFStringRef)@"com_multiplexapp_nonDVDFingerprint";
static NSArray* fileTypes = nil;

@interface _AppControllerExecuteToken : NSObject <ExecuteTokenProtocol> {
    NSInvocation* invocation;
}

- (id) initWithInvocation:(NSInvocation*)invoc;

@end

@implementation _AppControllerExecuteToken

- (id) initWithInvocation:(NSInvocation*)invoc
{
    if (self = [super init]) {
        invocation = [invoc retain];
    }
    
    return self;
}

- (void) approve
{
    [invocation invoke];
    [invocation release];
}

- (void) deny
{
    [invocation release];
}

@end


@interface ApplicationController (Private)

- (Movie*) _movieForAction;
- (void) _closeDrawerViewApproved;
- (void) _setCurrentDrawerViewControllerApproved:(id<DrawerViewControllerProtocol>)protocolObject;
- (void) _loadDatabase:(NSString*)pathToDatabaseFile isSampleData:(BOOL)isSample;
- (NSString*) _copySampleDatabase;
- (BOOL) _setMetadataValue:(CFTypeRef)data forAttributeName:(CFStringRef)keyName onItem:(MDItemRef)mdItem;
- (BOOL) _deleteMetadataAttribute:(CFStringRef)keyName forItem:(MDItemRef)mdItem;
- (NSString*) _getFingerprintForFile:(NSString*)filePath;
- (void) _addNonDVDMedia:(NSArray*)filenames;
- (void) _burnApproved:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo;
- (void) _setUnavailableMoviePredicate:(BOOL)hide;
- (void) _prepareToolTipWindowWithView:(NSView*)view attachedToPoint:(NSPoint)point inWindow:(NSWindow*)window onSide:(MAWindowPosition)position atDistance:(CGFloat)distance;

@end

@implementation ApplicationController
@synthesize searchQuery;
@synthesize parameters;
@synthesize appManagedObjectContext;
@synthesize selectedMovie;
@synthesize hoveredMovie;
@synthesize currentDrawerViewController;
@synthesize selectedSegment;
@synthesize movieContextMenu;
@synthesize moviesFilterPredicate;

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
            kCFBooleanTrue, @"HoverTooltipEnabled",
            kCFBooleanFalse, @"FullScreenOnLaunch",
            kCFBooleanFalse, @"SingleClickLaunchesMovie",
            kCFBooleanFalse, @"HideUnavailableMovies",
            kCFBooleanTrue, @"ShowToolTipSearch",
            nil
        ]];
        
        // Add in our file types
        if (!fileTypes) {
            fileTypes = [[NSArray arrayWithObjects:
                         @"3g2", @"3gp", @"3gp2", @"3gpp", @"3mm", @"60d", @"aep", @"ajp", @"amv", @"amx", @"arf", @"asf", @"asx", @"avb", @"avi", @"avs",
                         @"avs", @"axm", @"bik", @"bin", @"bix", @"box", @"bsf", @"byu", @"camrec", @"cvc", @"d2v", @"d3v", @"dat", @"dce", @"dif", @"dir", @"divx", @"dmb",
                         @"dpg", @"dv", @"dvr-ms", @"dvx", @"dxr", @"evo", @"eye", @"fbr", @"fbz", @"fcp", @"flc", @"flh", @"fli", @"flv", @"flx", @"gl", @"grasp", @"gvi", @"gvp",
                         @"hkm", @"ifo", @"imovieproj", @"imovieprojet", @"ivf", @"ivr", @"ivs", @"izz", @"izzy", @"lsf", @"lsx", @"m1pg", @"m1v", @"m21", @"m21", @"m2t",
                         @"m2ts", @"m2v", @"m4e", @"m4u", @"m4v", @"mgv", @"mj2", @"mjp", @"mkv", @"mnv", @"mod", @"moov", @"mov", @"movie", @"mp21", @"mp21", @"mp4", @"mpe", @"mpeg",
                         @"mpg", @"mpv2", @"mqv", @"msdvd", @"msh", @"mswmm", @"mts", @"mtv", @"mvb", @"mvc", @"mvd", @"nsv", @"nvc", @"ogm", @"par", @"pds", @"piv", @"playlist",
                         @"pmf", @"pro", @"prproj", @"prx", @"pxv", @"qt", @"qtch", @"qtz", @"rdb", @"rm", @"rmvb", @"rp", @"rts", @"rts", @"rum", @"rv", @"sbk", @"scm", @"scm", @"scn",
                         @"sfvidcap	", @"smil	", @"smk", @"smv", @"spl", @"srt", @"ssm", @"str", @"svi", @"swf", @"swi", @"tda3mt", @"tivo", @"tod", @"tp", @"ts", @"vdo", @"veg",
                         @"vf", @"vfw", @"vgz", @"vid", @"viewlet", @"viv", @"vivo", @"vlab", @"vob", @"vp6", @"vp7", @"vro", @"w32", @"wcp", @"wm", @"wmd", @"wmmp", @"wmv", @"wmx",
                         @"wvx", @"xvid", @"yuv", @"zm1", @"zm2", @"zm3", @"zmv",
                         nil] retain];
        }
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

        [self _loadDatabase:pathToDatabase isSampleData:NO];
        
        // Register our URL handler
        [NSURLProtocol registerClass:[MultiplexResourceURLProtocol class]];
    }
    return self;
}

#ifdef DUAL_OBJECT_CONTEXT

- (void) engineControllerObjectContextDidSave:(NSNotification*)saveNotification 
{
    [appManagedObjectContext performSelectorOnMainThread:@selector(mergeChangesFromContextDidSaveNotification:) withObject:saveNotification waitUntilDone:NO];

    if ([[self selectedMovie] isDeleted]) {
        [self setSelectedMovie:nil];
    }
}

- (void) appControllerObjectContextDidSave:(NSNotification*)saveNotification 
{
    [engineManagedObjectContext performSelectorOnMainThread:@selector(mergeChangesFromContextDidSaveNotification:) withObject:saveNotification waitUntilDone:NO];
}

#endif

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
    [notificationCenter addObserver:self selector:@selector(_combineMovies:) name:@"MultiplexCombineMoviesIntoSet" object:nil];
    [notificationCenter addObserver:self selector:@selector(_deleteMovieOrDisc:) name:@"MultiplexDeleteMovieOrDisc" object:nil];
    
    [notificationCenter addObserver:self selector:@selector(engineDidFinishInitialScan:) name:@"MultiplexEngineDidFinishInitialScan" object:nil];
    
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
    
    // Register Pasteboard types
    [[self window] registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];
    
    // Filter?
    BOOL hide = [[NSUserDefaults standardUserDefaults] boolForKey:@"HideUnavailableMovies"];
    [self _setUnavailableMoviePredicate:hide];
    
    // Jump to full screen?
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"FullScreenOnLaunch"] boolValue]) {
        // Do it on a delay to get the mouse coordinate system right.
        // Kinda hackish
        [self performSelector:@selector(toggleFullScreen:) withObject:nil afterDelay:0.1];
    }
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
        NSAlert* alert = [NSAlert alertWithMessageText:NSLocalizedString(@"The trial period for Multiplex has ended.", @"") defaultButton:nil alternateButton:NSLocalizedString(@"No thanks.", "") otherButton:nil informativeTextWithFormat:NSLocalizedString(@"We hope you enjoyed Multiplex! Would you like to visit the Multiplex website now?", @"")];
        [alert setAlertStyle:NSCriticalAlertStyle];
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

#pragma mark Public Methods

- (void) playDiscRequest:(NSNotification*)notification
{
    if ([notification object]) {
        Disc* d = (Disc*)[notification object];
        NSArray* allMedia = [d.allMedia allObjects];
        
        if ([allMedia count] > 0) {
            for (Media* media in allMedia) {
                if ([media.pathToFile isEqualToString:@"SAMPLE_DATA"]) {
                    NSAlert* sampleDataAlert = [NSAlert alertWithMessageText:@"Sample Data" 
                                                               defaultButton:@"Ok" 
                                                             alternateButton:nil 
                                                                 otherButton:nil 
                                                   informativeTextWithFormat:@"This is sample data only.  With real data, your movie would now play."];
                    [sampleDataAlert beginSheetModalForWindow:[drawerView window] modalDelegate:nil didEndSelector:nil contextInfo:nil];
                }
                else {
                    NSWorkspace* workspace = [NSWorkspace sharedWorkspace];
                    if (![media.type isEqualToString:@"public.dvdmedia"]) {
                        [workspace openFile:media.pathToFile];
                    }
                    else {
                        NSString* pathToExecutable = [workspace absolutePathForAppBundleWithIdentifier:@"com.apple.DVDPlayer"];
                        [workspace openFile:media.pathToFile withApplication:pathToExecutable];
                        break;
                    }
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

- (void) setCurrentDrawerViewController:(id<DrawerViewControllerProtocol>)protocolObject
{
    if (currentDrawerViewController) {
        NSInvocation* i = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:@selector(_setCurrentDrawerViewControllerApproved:)]];
        [i setTarget:self];
        [i setSelector:@selector(_setCurrentDrawerViewControllerApproved:)];
        [i retainArguments];
        [i setArgument:&protocolObject atIndex:2];
        
        _AppControllerExecuteToken* a = [[[_AppControllerExecuteToken alloc] initWithInvocation:i] autorelease];

        [currentDrawerViewController pleaseRelinquishControlAndApprove:a];
    }
    else {
        [self _setCurrentDrawerViewControllerApproved:protocolObject];
    }
}

- (void) approveMovieSelectionClick:(NSInvocation*)invocation forMovieLayer:(MovieLayer*)movieLayer
{
    [self removeToolTipWindow];
    
    if (selectedMovie == [movieLayer movie] && [drawerView isOpen]) {
        // DENY!
        return;
    }
    
    if (currentDrawerViewController) {
        _AppControllerExecuteToken* a = [[[_AppControllerExecuteToken alloc] initWithInvocation:invocation] autorelease];
        [currentDrawerViewController pleaseRelinquishControlAndApprove:a];
    }
    else {
        [invocation invoke];
    }
}

- (void) showMovieDetailForMovie:(Movie*)movie
{
    [movies setSelectedObjects:[NSArray arrayWithObject:movie]];
    if (!movieDetailController) {
        movieDetailController = [[MovieDetailController alloc] initWithApplicationController:self drawerView:drawerView];
    }

    [self setCurrentDrawerViewController:(id<DrawerViewControllerProtocol>)movieDetailController];
}

- (void) showMovieDetailAndSelectHomeTabForMovie:(Movie*)movie
{
    [self showMovieDetailForMovie:movie];
    [movieDetailController showHomeTab];
    [[self window] makeFirstResponder:mainView];
}

- (void) showMovieDetailAndSelectDiscsTabMovie:(Movie*)movie
{
    [self showMovieDetailForMovie:movie];
    [movieDetailController showDiscsTab];
}


- (void) showMovieLookupForMovie:(Movie*)movie byTitle:(NSNumber*)byTitle
{
    if (![self isDrawerViewOpen]) {
        [drawerView toggle:nil];
    }
    
    [movies setSelectedObjects:[NSArray arrayWithObject:movie]];
    if (!movieLookupController) {
        movieLookupController = [[MovieLookupController alloc] initWithApplicationController:self drawerView:drawerView];
    }
    [self setCurrentDrawerViewController:(id<DrawerViewControllerProtocol>)movieLookupController];
    
    if (byTitle && [byTitle boolValue]) {
        [movieLookupController skipToTitleEntry:nil];
    }
    else {
        [movieLookupController skipToUPCEntry:nil];
    }
}

- (void) closeDrawerView:(NSNotification*)notification
{
    if (currentDrawerViewController) {
        NSInvocation* i = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:@selector(_closeDrawerViewApproved)]];
        [i setSelector:@selector(_closeDrawerViewApproved)];
        [i setTarget:self];
        
        _AppControllerExecuteToken* a = [[[_AppControllerExecuteToken alloc] initWithInvocation:i] autorelease];
        
        [currentDrawerViewController pleaseRelinquishControlAndApprove:a];
    }
    else {
        [self _closeDrawerViewApproved];
    }
}

- (void) openInfoView:(NSNotification*)notification
{
    [self setSelectedMovieFromNotificationIfNecessary:notification];
    
    [drawerView openDrawer];
    [movieDetailController showHomeTab];
}

- (void) engineDidFinishInitialScan:(NSNotification*)notification
{
    // Turn off the spinner
    //[startUpSpinnerView retain];
    [[startUpSpinnerView animator] setHidden:YES];
    //[[startUpSpinnerView animator] removeFromSuperview];
    
    // Turn on the "no discs" if necessary
    if ([[movies content] count] == 0) {
        [self performSelector:@selector(bindNoDiscsView) withObject:nil afterDelay:1.0];
    }
    
    //[startUpSpinnerView release];
}

- (void) bindNoDiscsView
{
    if ([[movies content] count] == 0)
    {
        //[[noDiscsView animator] setHidden:NO];
        [[noDiscsView animator] bind:@"hidden" toObject:movies withKeyPath:@"content.@count" options:nil];        
    }
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

- (NSArray*) feedParametersForUpdater:(SUUpdater*)updater sendingSystemProfile:(BOOL)sendingProfile
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
                [[self window] makeFirstResponder:mainView];
            } else {
                cLayoutManager = NSClassFromString([[NSUserDefaults standardUserDefaults] objectForKey:kMultiplexDrawerIsClosedLayoutManagerClass]);
                if (!cLayoutManager)
                {
                    cLayoutManager = [StadiumLayoutManager class];
                }
                [mainView setFloorLayerLayoutManagerClass:cLayoutManager];
                
                [drawerView setContentView:nil];
                [[self window] makeFirstResponder:mainView];
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
                
                [mainView setNoSelectedMovieLayer];
                
                if ([drawerView isOpen]) {
                    [drawerView setContentView:noMovieSelectedView];
                }
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

- (BOOL) isInFullScreen
{
    return [[NSApp mainWindow] isBig];
}

- (BOOL) isDrawerViewOpen
{
    return [drawerView isOpen];
}

- (void) setSearchQuery:(NSString*)_searchQuery
{
    [self removeToolTipWindow];
    
    if (_searchQuery != searchQuery) {
        [searchQuery release];
        searchQuery = [_searchQuery retain];
        if (searchQuery) {
            movies.filterPredicate = [NSPredicate predicateWithFormat:@"(title beginswith[c] %@) or (title contains[c] %@)", searchQuery, [@" " stringByAppendingString:searchQuery]];
        } else {
            movies.filterPredicate = nil;
        }
        NSLog(@"%@, %i", movies.filterPredicate, [[movies arrangedObjects] count]);
    }
}

- (IBAction) toggleFullScreen:(id)sender
{
    [mainWindowContentView toggleFullScreen];
    
    if ([self isInFullScreen]) {
        [windowResizeThumb setHidden:YES];
    }
    else {
        [windowResizeThumb setHidden:NO];
    }
}

- (IBAction) addNonDVDMovie:(id)sender
{
    NSOpenPanel* openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseFiles:YES];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setResolvesAliases:YES];
    [openPanel setAllowsMultipleSelection:YES];
    [openPanel beginSheetForDirectory:nil 
                                 file:nil 
                                types:fileTypes 
                       modalForWindow:[drawerView window]
                        modalDelegate:self
                       didEndSelector:@selector(_addNonDVDMediaPanelDidEnd:returnCode:contextInfo:) 
                          contextInfo:nil];
}

- (void) _deleteMovieOrDisc:(NSNotification*)notification
{
    id obj = [notification object];
    Movie* m = nil;
    Disc* d = nil;

    if (obj) {
        NSMutableArray* allMedia = [NSMutableArray array];
        
        if ([obj isKindOfClass:[Movie class]]) {
            m = (Movie*)obj;
        }
        else if ([obj isKindOfClass:[Disc class]]) {
            d = (Disc*)obj;
        }
        
        if (m) {
            // Delete from any media
            NSMutableArray* allDiscs = [NSMutableArray arrayWithArray:[[m allDiscs] allObjects]];
            for (Disc* d in allDiscs) {
                [allMedia addObjectsFromArray:[[d allMedia] allObjects]];
            }
        }
        else if (d) {
            [allMedia addObjectsFromArray:[[d allMedia] allObjects]];
        }
        
        int localCount = 0;
        for (Media* media in allMedia) {
            if (media.isLocal) {
                localCount ++;
            }
        }

        [deletePanel prepareForDelete:obj withNumberOfLocalMediaObjects:localCount];
        
        NSArray* contextInfo = [[NSArray alloc] initWithObjects:obj, allMedia, nil];
        [NSApp beginSheet:deletePanel 
           modalForWindow:[drawerView window] 
            modalDelegate:self 
           didEndSelector:@selector(_deleteAlertDidEnd:returnCode:contextInfo:) 
              contextInfo:contextInfo]; 
    }
}

- (void) deleteCurrentMovie
{
    Movie* m = [self _movieForAction];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"MultiplexDeleteMovieOrDisc" object:m];
}

- (void) _deleteAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    if (0 == returnCode) {
        return;
    }
    else {
        NSArray* arrToDealWith = (NSArray*)contextInfo;
        NSManagedObject* toDelete = (NSManagedObject*)[arrToDealWith objectAtIndex:0];
        NSArray* allMedia = (NSArray*)[arrToDealWith objectAtIndex:1];
        
        // Unregister media
        for (Media* m in allMedia) {
            if (![m.type isEqualToString:@"public.dvdmedia"] && ![m.type isEqualToString:@"SAMPLE_DATA"]) {
                MDItemRef itemRef = MDItemCreate(NULL, (CFStringRef)m.pathToFile);
                [self _deleteMetadataAttribute:kMDItemMultiplexNonDVDFingerprint forItem:itemRef];
                CFRelease(itemRef);
            }
        }
        
        // Delete files?
        if (2 == returnCode) {
            for (Media* m in allMedia) {
                if (![m.pathToFile isEqualToString:@"SAMPLE_DATA"]) {
                    const char* filePath = [m.pathToFile cStringUsingEncoding:NSUTF8StringEncoding];
                    OSStatus deleteError = FSPathMoveObjectToTrashSync(filePath, NULL, kFSFileOperationDefaultOptions);
                    
                    if (deleteError) {
                        NSAlert* alert = [NSAlert alertWithMessageText:@"Could not delete the media" 
                                                         defaultButton:@"Ok" 
                                                       alternateButton:nil 
                                                           otherButton:nil 
                                             informativeTextWithFormat:[NSString stringWithFormat:@"Could not delete the media file\n%@\n\nPlease delete it manually.", m.pathToFile]];
                        [alert beginSheetModalForWindow:[drawerView window] modalDelegate:nil didEndSelector:nil contextInfo:nil];
                    }                
                }
            } 
        }
                
        // Delete
        if ([toDelete isKindOfClass:[Movie class]]) {
            [self setSelectedMovie:nil];
        }
        
        [appManagedObjectContext deleteObject:toDelete];
        [arrToDealWith release];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"MultiplexDiscViewResetDiscs" object:nil];
}

- (void) windowDidResignMain:(NSNotification*)notification
{
    NSLog(@"resigned");
    if (mainWindowContentView && [mainWindowContentView isInFullScreenMode]) {
        [mainWindowContentView toggleFullScreen];
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

- (MovieURL*) getAmazonURL:(Movie*)movie
{
    NSManagedObjectContext* managedObjectContext = [movie managedObjectContext];
    NSEntityDescription* movieURLEntity = [NSEntityDescription entityForName:@"MovieURL" inManagedObjectContext:managedObjectContext];
    
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:movieURLEntity];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"movie == %@ and siteName = %@", movie, @"Amazon"]]; 
    NSError* error = nil;
    NSArray* results = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    [fetchRequest release];
    if (!error && [results count]) {
        return [results objectAtIndex:0];
    }
    return nil; 
}

- (void) showSearchTooltip {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"ShowToolTipSearch"]) {
        CGFloat centerPoint = [searchField frame].origin.x + ([searchField frame].size.width / 2.0);
        NSPoint windowPoint = NSMakePoint(centerPoint, [searchField frame].origin.y);
        [self _prepareToolTipWindowWithView:searchExplanationView attachedToPoint:windowPoint inWindow:[drawerView window] onSide:MAPositionTop atDistance:20.0];
    }
    
}

- (void) removeToolTipWindow
{
    if (tipWindow) {
        [[tipWindow animator] setAlphaValue:0.0];
        [[tipWindow parentWindow] removeChildWindow:tipWindow];
        [tipWindow release], tipWindow = nil;
    }
}

#pragma mark IBActions

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

- (IBAction) showPreferencesWindow:(id)sender
{
    if (!preferencesWindowController)
    {
        preferencesWindowController = [[PreferencesWindowController alloc] initWithApplicationController:self];
    }
    
    [[preferencesWindowController window] makeKeyAndOrderFront:self];
}

- (IBAction) checkForUpdates:(id)sender
{
    [[SUUpdater sharedUpdater] checkForUpdates:sender];
}

- (IBAction) showUserVoiceFeedbackSheet:(id)sender
{
    [self removeToolTipWindow];
    
    [userVoiceFeedbackPanel setFrame:[self.window.contentView frame] display:YES];
    
    [NSApp beginSheet:(NSWindow*)userVoiceFeedbackPanel 
       modalForWindow:[mainView window] 
        modalDelegate:self 
       didEndSelector:@selector(userVoicePanelDidEnd:returnCode:contextInfo:) 
          contextInfo:nil];
}

- (IBAction) showSampleData:(id)sender
{
    [self removeToolTipWindow];
    
    // Shut down the current engine
    [engineController shutdown];
    [engineController release], engineController = nil;
    
    // Copy the database
    NSString* pathToSampleDatabase = [self _copySampleDatabase];
    
    // Load up our database
    [self _loadDatabase:pathToSampleDatabase isSampleData:YES];
    
    // Restart the engine
    engineController = [[EngineController alloc] initWithManagedObjectContext:engineManagedObjectContext];
    
    NSEntityDescription* discEntity = [NSEntityDescription entityForName:@"Disc" inManagedObjectContext:engineManagedObjectContext];
    NSEntityDescription* mediaEntity = [NSEntityDescription entityForName:@"Media" inManagedObjectContext:engineManagedObjectContext];
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:discEntity];
    NSArray* discsToAddMediaTo = [engineManagedObjectContext executeFetchRequest:fetchRequest error:nil];
    
    int i = 0;
    for (Disc* disc in discsToAddMediaTo) {
        Media* m = [[Media alloc] initWithEntity:mediaEntity insertIntoManagedObjectContext:engineManagedObjectContext];
        m.disc = disc;
        m.isAvailable = [NSNumber numberWithBool:YES];
        m.isLocal = [NSNumber numberWithBool:YES];
        m.pathToFile = @"SAMPLE_DATA";
        m.tag = [NSString stringWithFormat:@"%036d", i++];
        m.type = @"SAMPLE_DATA";
    }
    
    NSError* error = nil;
    [engineManagedObjectContext save:&error];
}

- (IBAction) refreshInfoFromInternetByUPC:(id)sender
{
    [self removeToolTipWindow];
    
    // TODO: DRY on both refreshInfo... functions
    Movie* movieForAction = [self _movieForAction];
    
    if (movieForAction != selectedMovie) {
        // Ask the app for permission
        MovieLayer* layerToSelect = [mainView.layersByID objectForKey:[movieForAction objectID]];
        NSNumber* byTitle = [NSNumber numberWithBool:NO];
        
        NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:@selector(showMovieLookupForMovie:byTitle:)]];
        [invocation setTarget:self];
        [invocation setSelector:@selector(showMovieLookupForMovie:byTitle:)];
        [invocation retainArguments];
        [invocation setArgument:&movieForAction atIndex:2];
        [invocation setArgument:&byTitle atIndex:3];
        [self approveMovieSelectionClick:invocation forMovieLayer:layerToSelect];
    }
    else {
        [self showMovieLookupForMovie:movieForAction byTitle:[NSNumber numberWithBool:YES]];
    }
}

- (IBAction) refreshInfoFromInternetByTitle:(id)sender
{
    [self removeToolTipWindow];
    
    Movie* movieForAction = [self _movieForAction];
    
    if (movieForAction != selectedMovie) {
        // Ask the app for permission
        MovieLayer* layerToSelect = [mainView.layersByID objectForKey:[movieForAction objectID]];
        NSNumber* byTitle = [NSNumber numberWithBool:YES];

        NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:@selector(showMovieLookupForMovie:byTitle:)]];
        [invocation setTarget:self];
        [invocation setSelector:@selector(showMovieLookupForMovie:byTitle:)];
        [invocation retainArguments];
        [invocation setArgument:&movieForAction atIndex:2];
        [invocation setArgument:&byTitle atIndex:3];
        [self approveMovieSelectionClick:invocation forMovieLayer:layerToSelect];
    }
    else {
        [self showMovieLookupForMovie:movieForAction byTitle:[NSNumber numberWithBool:YES]];
    }
}

- (IBAction) deleteMovie:(id)sender
{
    [self removeToolTipWindow];
    [self deleteCurrentMovie];
}

- (IBAction) buyFromAmazon:(id)sender
{
    [self removeToolTipWindow];
    
    MovieURL* url = [self getAmazonURL:[self _movieForAction]];
    NSString* urlString = url.url;
    NSURL* nsurl = [NSURL URLWithString:urlString];
    
    [[NSWorkspace sharedWorkspace] openURL:nsurl];
}

- (IBAction) burnWithToast:(id)sender
{
    [self removeToolTipWindow];

    Media* m = nil;
    
    // Get the media
    for (Disc* d in [self _movieForAction].allDiscs) {
        if (d.localMediaCount > 0) {
            for (Media* discMedia in d.allMedia) {
                if (discMedia.isLocal) { // && ![discMedia isPhysicalMedia]) {
                    if (m) {
                        if ([m isPhysicalMedia] && ![discMedia isPhysicalMedia]) {
                            m = discMedia;
                        }
                    }
                    else {
                        m = discMedia;
                    }
                }
            }
        }
    }
    
    if (!m) {
        NSAlert* a = [NSAlert alertWithMessageText:@"Media disconnected" 
                                     defaultButton:@"Ok" 
                                   alternateButton:@"Cancel" 
                                       otherButton:nil 
                         informativeTextWithFormat:@"The media for this movie has been recently disconnected.  This action is not possible."];
        
        [a beginSheetModalForWindow:[NSApp mainWindow] modalDelegate:self didEndSelector:@selector(_burnApproved:returnCode:contextInfo:) contextInfo:m];
    }
    else if (m && [m isPhysicalMedia]) {
        NSAlert* a = [NSAlert alertWithMessageText:@"Trying to copy physical media" 
                                     defaultButton:@"Ok" 
                                   alternateButton:@"Cancel" 
                                       otherButton:nil 
                         informativeTextWithFormat:@"You are attempting to copy a physical DVD. This may cause issues.  If you would like to continue, click OK."];
        
        [a beginSheetModalForWindow:[NSApp mainWindow] modalDelegate:self didEndSelector:@selector(_burnApproved:returnCode:contextInfo:) contextInfo:m];
    }
    else {
        [self _burnApproved:nil returnCode:NSAlertDefaultReturn contextInfo:m];
    }
}

- (IBAction) toggleHideUnavailableMovies:(id)sender
{
    [self removeToolTipWindow];
    
    // This is backwards, no big deal
    BOOL hidden = ![[NSUserDefaults standardUserDefaults] boolForKey:@"HideUnavailableMovies"];
    [self _setUnavailableMoviePredicate:hidden];
}

- (IBAction) playMovie:(id)sender
{
    [self removeToolTipWindow];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"MultiplexPlayMovie" object:nil];
}

- (IBAction) focusSearch:(id)sender
{    
    [self removeToolTipWindow];
    [[drawerView window] makeFirstResponder:searchField];        
}

- (IBAction) goToMultiplexSupport:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://multiplexapp.com/support/"]];
}

- (IBAction) dontShowTooltipAgain:(id)sender
{
    NSView* parentView = [(NSView*)sender superview];
    
    if (parentView == searchExplanationView) {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"ShowToolTipSearch"];
    }
    
    [self removeToolTipWindow];
}

- (IBAction) resetToolTipAlerts:(id)sender
{
    // Reset all tooltip stuff
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"ShowToolTipSearch"];
    
}

#pragma mark Private Methods

- (Movie*) _movieForAction
{
    if (self.hoveredMovie) {
        return self.hoveredMovie;
    }
    else {
        return self.selectedMovie;
    }
}

- (NSString*) _copySampleDatabase
{
    NSString* baseFolder = @"/Library/Application Support/Multiplex";
    NSString* sampleDataFile = @"SampleData.database";
    
    NSString* resourcePathToDatabase = [[NSBundle mainBundle] pathForResource:@"SampleData" ofType:@"database"];
    NSString* newPathToDatabase = [baseFolder stringByAppendingPathComponent:sampleDataFile];
    
    NSFileManager* fm = [NSFileManager defaultManager];
    
    // Check to see if it exists
    if ([fm fileExistsAtPath:newPathToDatabase])
    {
        [fm removeFileAtPath:newPathToDatabase handler:nil];
    }
    
    [fm copyItemAtPath:resourcePathToDatabase toPath:newPathToDatabase error:nil];
    
    return newPathToDatabase;
}

-(void) _loadDatabase:(NSString*)pathToDatabaseFile isSampleData:(BOOL)isSample
{
    // DEBUG
    //pathToDatabaseFile = [[NSBundle mainBundle] pathForResource:@"SampleData" ofType:@"database"];
    
    // KVO
    [self willChangeValueForKey:@"managedObjectModel"];
    [self willChangeValueForKey:@"persistentStoreCoordinator"];
    [self willChangeValueForKey:@"engineManagedObjectContext"];
    [self willChangeValueForKey:@"appManagedObjectContext"];
    
    // Release
    //[appManagedObjectContext release],
    appManagedObjectContext = nil;
    [engineManagedObjectContext release], engineManagedObjectContext = nil;
    [persistentStoreCoordinator release], persistentStoreCoordinator = nil;
    [managedObjectModel release], managedObjectModel = nil;
    
    NSError* error = nil;
    NSFileManager* fileManager = [NSFileManager defaultManager];
    
    managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"MultiplexOnePointZero" ofType:@"mom"]]];
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:managedObjectModel];
    
    NSDictionary* pscOptions = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:NSMigratePersistentStoresAutomaticallyOption];
    
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:[NSURL fileURLWithPath:pathToDatabaseFile] options:pscOptions error:&error]) {
        if (!isSample) {
            [fileManager removeItemAtPath:pathToDatabaseFile error:nil];
            if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:[NSURL fileURLWithPath:pathToDatabaseFile] options:pscOptions error:&error]) {
                [NSException raise:NSStringFromClass([self class]) format:@"Unable to create a fresh database."];
            }
        }
    }
    
    engineManagedObjectContext = [[NSManagedObjectContext alloc] init];
    [engineManagedObjectContext setPersistentStoreCoordinator:persistentStoreCoordinator];
    
    appManagedObjectContext = engineManagedObjectContext; 
    
#ifdef DUAL_OBJECT_CONTEXT
    
    appManagedObjectContext = [[NSManagedObjectContext alloc] init];
    [appManagedObjectContext setPersistentStoreCoordinator:persistentStoreCoordinator];
    
    NSNotificationCenter* notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self selector:@selector(engineControllerObjectContextDidSave:) name:NSManagedObjectContextDidSaveNotification object:engineManagedObjectContext];
    [notificationCenter addObserver:self selector:@selector(appControllerObjectContextDidSave:) name:NSManagedObjectContextDidSaveNotification object:appManagedObjectContext];
    
#endif
    
    // KVO
    [self didChangeValueForKey:@"managedObjectModel"];
    [self didChangeValueForKey:@"persistentStoreCoordinator"];
    [self didChangeValueForKey:@"engineManagedObjectContext"];
    [self didChangeValueForKey:@"appManagedObjectContext"];
}


- (void) _closeDrawerViewApproved
{
    [mainView resetCurrentlySelectedMovieLayer];
    
    [drawerView closeDrawer];
    [[self window] makeFirstResponder:mainView];            
}

- (BOOL) _setMetadataValue:(CFTypeRef)data forAttributeName:(CFStringRef)keyName onItem:(MDItemRef)mdItem
{
    typedef OSStatus (*MDItemSetAttribute_type)(MDItemRef, CFStringRef, CFTypeRef);
    static MDItemSetAttribute_type mdItemSetAttributeFunc = NULL;
    static bool didSymbolLookup = false;
    if (!didSymbolLookup) {
        didSymbolLookup = true;
        CFBundleRef metadataBundle = CFBundleGetBundleWithIdentifier(CFSTR("com.apple.Metadata"));
        if (!metadataBundle) {
            return NO;
        }
        
        mdItemSetAttributeFunc = (MDItemSetAttribute_type)CFBundleGetFunctionPointerForName(metadataBundle, CFSTR("MDItemSetAttribute"));
    }
    if (!mdItemSetAttributeFunc) {
        return NO;
    }
    
    Boolean b = mdItemSetAttributeFunc(mdItem, keyName, data);
    return (BOOL)b;
}

- (BOOL) _deleteMetadataAttribute:(CFStringRef)keyName forItem:(MDItemRef)mdItem
{
    typedef OSStatus (*MDItemRemoveAttribute_type)(MDItemRef, CFStringRef);
    static MDItemRemoveAttribute_type mdItemRemoveAttributeFunc = NULL;
    static bool didSymbolLookup = false;
    if (!didSymbolLookup) {
        didSymbolLookup = true;
        CFBundleRef metadataBundle = CFBundleGetBundleWithIdentifier(CFSTR("com.apple.Metadata"));
        if (!metadataBundle) {
            return NO;
        }
        
        mdItemRemoveAttributeFunc = (MDItemRemoveAttribute_type)CFBundleGetFunctionPointerForName(metadataBundle, CFSTR("MDItemRemoveAttribute"));
    }
    if (!mdItemRemoveAttributeFunc) {
        return NO;
    }
    
    BOOL b = mdItemRemoveAttributeFunc(mdItem, keyName);
    return b;
}

- (void) _licensingAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    if (NSAlertDefaultReturn == returnCode) {
        //[[SUUpdater sharedUpdater] checkForUpdates:self];
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://multiplexapp.com"]];
    }
}

- (void) _setCurrentDrawerViewControllerApproved:(id<DrawerViewControllerProtocol>)protocolObject
{
    [mainView resetCurrentlySelectedMovieLayer];
    
    [currentDrawerViewController release], currentDrawerViewController = nil;
    
    currentDrawerViewController = [protocolObject retain];
    [currentDrawerViewController takeControl];
}

- (void)_addNonDVDMediaPanelDidEnd:(NSOpenPanel*)panel returnCode:(int)returnCode contextInfo:(void*)contextInfo
{
    if (returnCode == NSOKButton) {
        [self _addNonDVDMedia:[panel filenames]];
    }
}

- (void) _addNonDVDMedia:(NSArray*)filenames
{
    @try {
        NSMutableArray* noPermissionsFiles = [NSMutableArray array];
        
        for (NSString* fileName in filenames) {
            
            // Fingerprint!
            NSString* fingerprint = nil;
            // Tag the item Spotlight style
            MDItemRef mditem = MDItemCreate(kCFAllocatorDefault, (CFStringRef)fileName);
            
            // No item means permissions errors
            if (!mditem) {
                [noPermissionsFiles addObject:fileName];
                continue;
            }
            
            // If we have a fingerprint, this has been tagged before
            fingerprint = [self _getFingerprintForFile:fileName];
            
            // If we can't add info, there are permissions errors.
            if (!fingerprint || ![self _setMetadataValue:(CFTypeRef)fingerprint forAttributeName:kMDItemMultiplexNonDVDFingerprint onItem:mditem]) {
                [noPermissionsFiles addObject:fileName];
            }
            
            CFRelease(mditem);
        }
        
        // If we couldn't add some
        if ([noPermissionsFiles count]) {
            NSMutableString* noPermissionsFileNames = nil;
            for (NSString* fileName in noPermissionsFiles) {
                if (noPermissionsFileNames) {
                    [noPermissionsFileNames appendFormat:@"\n%@", fileName];
                }
                else {
                    noPermissionsFileNames = [NSMutableString stringWithFormat:@"%@", fileName];
                }
            }
            
            NSAlert* alert = [NSAlert alertWithMessageText:@"Multiplex could not import some movies"
                                             defaultButton:@"Ok" 
                                           alternateButton:nil 
                                               otherButton:nil 
                                 informativeTextWithFormat:[NSString stringWithFormat:@"Multiplex could not read the following files. This could be a permissions problem.  Please make sure you have read/write permissions to the following files, and try again. \n\n%@", noPermissionsFileNames]];
            [alert beginSheetModalForWindow:[drawerView window] modalDelegate:nil didEndSelector:nil contextInfo:nil];
        }
        
    }
    @finally {        
        [[startUpSpinnerView animator] setHidden:YES];
    }
}

- (NSString*) _getFingerprintForFile:(NSString*)filePath
{
    NSFileHandle* handle = [NSFileHandle fileHandleForReadingAtPath:filePath];
    NSString* fp = nil;
    
    @try {
        NSData* data = [handle readDataOfLength:64 * 1024];
        fp = [data IHLFingerprint];
    }
    @catch (NSException* ex) {
        NSLog(@"Exception caught: %@", [ex userInfo]);
    }
    @finally {
        [handle closeFile];
    }
    
    return fp;
}

- (void) _burnApproved:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    if (returnCode == NSAlertDefaultReturn) {
        Media* m = (Media*)contextInfo;
        
        NSString* s = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:@"com.roxio.Toast"];
        [[NSWorkspace sharedWorkspace] openFile:m.pathToFile withApplication:s];
    }
}

- (BOOL) _setBurnPossible
{
    static BOOL alreadyDetermined = NO;
    static BOOL toastIsAvailable = NO;
    
    if (!alreadyDetermined) {
        // Determine if we have a proper version of toast
        NSString* s = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:@"com.roxio.Toast"];
        if (s && ![s isEqualToString:@""]) {
            NSBundle* b = [NSBundle bundleWithPath:s];
            if (b && [[b version] intValue] >= 9) {
                toastIsAvailable = YES;
            }
        }
    }
    
    if (toastIsAvailable && [self _movieForAction].localMediaCount) {
        return YES;
    }
    return NO;
    
}

- (void) _setUnavailableMoviePredicate:(BOOL)hide
{
    if (hide) {
        self.moviesFilterPredicate = [NSPredicate predicateWithFormat:@"availableDiscCount > 0"];
    }
    else {
        self.moviesFilterPredicate = nil;
    }
}

- (void) _prepareToolTipWindowWithView:(NSView*)view attachedToPoint:(NSPoint)point inWindow:(NSWindow*)window onSide:(MAWindowPosition)position atDistance:(CGFloat)distance
{
    tipWindow = [[MAAttachedWindow alloc] initWithView:view 
                                       attachedToPoint:point 
                                              inWindow:window 
                                                onSide:position 
                                            atDistance:20.0];
    
    [tipWindow setAlphaValue:0.0];
    [[drawerView window] addChildWindow:tipWindow ordered:NSWindowAbove];
    [[tipWindow animator] setAlphaValue:1.0];
}

- (void) _combineMovies:(NSNotification*)notification
{
    Movie* m = (Movie*)[notification object];
    if (!m) {
        NSLog(@"Got combine movie call without movie object");
    }
    else {
        Movie* selected = selectedMovie;
        int oldDiscNumber = 1;
        int nextDiscNumber = [selected.allDiscs count] + 1;
        
        for (Disc* d in [m discsInOrder]) {
            if (d.discTitle == nil) {
                if ([m.title rangeOfString:@"disc" options:NSCaseInsensitiveSearch].location != NSNotFound) {
                    d.discTitle = m.title;
                }
                else {
                    d.discTitle = [NSString stringWithFormat:@"%@ - Disc %d", m.title, oldDiscNumber];                    
                }
            }
            d.movie = selected;
            d.number = [NSNumber numberWithInt:nextDiscNumber];
            oldDiscNumber ++;
            nextDiscNumber ++;
        }
        
        [appManagedObjectContext deleteObject:m];
        
        NSError* error = nil;
        [appManagedObjectContext save:&error];
        if (error) {
            NSLog(@"Error combining movies: %@", [error userInfo]);
        }
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"MultiplexCombineMoviesDidFinish" object:nil];
}

#pragma mark Dragging protocol methods

- (NSDragOperation) draggingEntered:(id<NSDraggingInfo>)sender 
{
    NSPasteboard* pasteBoard = [sender draggingPasteboard];
    BOOL allowDrag = NO;
    
    NSArray* fileNames = [pasteBoard propertyListForType:NSFilenamesPboardType];
   
    for (NSString* fileName in fileNames) {
        NSString* extension = [fileName pathExtension];
        for (NSString* ext in fileTypes) {
            NSRange r = [extension rangeOfString:ext options:NSCaseInsensitiveSearch];
            if (r.location == 0 && r.length == [extension length]) {
                allowDrag = YES;
                break;
            }
        }
        
        if (allowDrag) {
            break;
        }
    }
    
    if (allowDrag) {
        [[startUpSpinnerView animator] setHidden:NO];
        return NSDragOperationCopy;
    } else {
        [[startUpSpinnerView animator] setHidden:YES];
        return NSDragOperationNone;
    }
}

- (void) draggingExited:(id<NSDraggingInfo>)sender
{
    [[startUpSpinnerView animator] setHidden:YES];
}

- (BOOL) performDragOperation:(id<NSDraggingInfo>)sender 
{
    NSPasteboard* pasteBoard = [sender draggingPasteboard];
    NSArray* fileNames = [pasteBoard propertyListForType:NSFilenamesPboardType];
    NSMutableArray* filesToAdd = [NSMutableArray array];
    for (NSString* fileName in fileNames) {
        NSString* extension = [fileName pathExtension];
        for (NSString* ext in fileTypes) {
            NSRange r = [extension rangeOfString:ext options:NSCaseInsensitiveSearch];
            if (r.location == 0 && r.length == [extension length]) {
                [filesToAdd addObject:fileName];
                break;
            }
        }
    }
    
    if ([filesToAdd count]) {
        [self _addNonDVDMedia:filesToAdd];
        return YES;
    }
    else {
        [[startUpSpinnerView animator] setHidden:YES];
        return NO;
    }
}

#pragma mark Application Delegate Methods

- (void) application:(NSApplication*)sender openFiles:(NSArray*)filenames
{
    [self _addNonDVDMedia:filenames];
    [NSApp replyToOpenOrPrint:NSApplicationDelegateReplySuccess];
}

#pragma mark Context Menu (NSMenu) Delegate Methods

- (void)menuWillOpen:(NSMenu*)menu
{
    if ([self getAmazonURL:[self _movieForAction]]) {
        [buyFromAmazonMenuItem setEnabled:YES];
    }
    else {
        [buyFromAmazonMenuItem setEnabled:NO];
    }
    
    [burnWithToastMenuItem setHidden:![self _setBurnPossible]];
}

@end






