#import "MovieDetailDiscsView.h"
#import "Movie.h"
#import "Disc.h"
#import "Media.h"
#import "MultiplexColorFactory.h"
#import "ApplicationResources.h"
#import "MovieDetailController.h"
#import "DiscDropView.h"
#import "DiscRenameAndMakeIndependentMovie.h"

#import <Toolkit/Toolkit.h>
#import <JSONKit/JSONKit.h>
#import <WebKit/WebKit.h>

@interface MovieDetailDiscsView (Private)

- (void) _setUpDiscLayers;
- (void) _setUpContextMenuItems;
- (Disc*) _discForManagedObjectID:(NSString*)coreDataObjectId;

@end

@implementation MovieDetailDiscsView (JavascriptHooks)

+ (BOOL) isSelectorExcludedFromWebScript:(SEL)selector {
    if (selector == @selector(signalIsReady) ||
        selector == @selector(playDisc:) ||
        selector == @selector(reorderDiscs:) ||
        selector == @selector(setCurrentCoreDataObjectID:) ||
        selector == @selector(renameDisc:toName:)) {
        return NO;
    }
    return YES;
}

+ (NSString*) webScriptNameForSelector:(SEL)sel
{
    if (sel == @selector(playDisc:))
        return @"playDisc";
    if (sel == @selector(reorderDiscs:)) {
        return @"reorderDiscs";
    }
    if (sel == @selector(setCurrentCoreDataObjectID:)) {
        return @"setDisc";
    }
    if (sel == @selector(renameDisc:toName:)) {
        return @"renameDisc";
    }
    return nil;
}

@end


@implementation MovieDetailDiscsView

@synthesize movie;
@synthesize isReady;

- (void) awakeFromNib
{
    [webView setDrawsBackground:NO];
    [webView setPreferences:[ApplicationResources discsViewWebPreferences]];
    [webView setFrameLoadDelegate:self];
    [webView setUIDelegate:self];
    
    // Load the initial html
    NSString* html = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"discs-tab" ofType:@"html"]];
    [[webView mainFrame] loadHTMLString:html baseURL:[NSURL URLWithString:@""]];
    
    dropView = [[DiscDropView alloc] init];
    [dropView setHidden:YES];
    [self addSubview:dropView];
    [dropView setFrame:[webView frame]];
    
    [self _setUpContextMenuItems];
    
    NSNotificationCenter* dc = [NSNotificationCenter defaultCenter];
    [dc addObserver:self selector:@selector(_dragInitiated:) name:@"MovieDragInitiated" object:nil];
    [dc addObserver:self selector:@selector(_dragCompleted:) name:@"MovieDragCompleted" object:nil];
    [dc addObserver:self selector:@selector(_combineDidFinish:) name:@"MultiplexCombineMoviesDidFinish" object:nil];
    
    [dc addObserver:self selector:@selector(_resetDiscs:) name:@"MultiplexDiscViewResetDiscs" object:nil];
}

- (void) dealloc
{
    [renameMenuItem release];
    [removeMenuItem release];
    [sepMenuItem release];
    [deleteFromMultiplexItem release];
    [dropView release];
    [super dealloc];
}

- (void) setMovie:(Movie*)_selectedMovie
{
    if (movie != _selectedMovie) {
        [movie release];
        movie = [_selectedMovie retain];
    }

    if (isReady) {
        [self _setUpDiscLayers];        
    }
}

#pragma mark Private Methods

- (void) _setUpDiscLayers
{
    if (movie) {
        NSMutableDictionary* dict = [NSMutableDictionary dictionary];
        NSMutableArray* arr = [NSMutableArray array];
        
        // Loop the discs
        for (Disc* disc in [movie discsInOrder]) {
            NSMutableDictionary* discDict = [NSMutableDictionary dictionary];
            [discDict setValue:disc.number forKey:@"number"];
            [discDict setValue:(disc.discTitle ? disc.discTitle : [NSString stringWithFormat:@"Disc %i", [disc.number intValue]]) forKey:@"title"];
            [discDict setValue:disc.synopsis forKey:@"synopsis"];
            [discDict setValue:[NSString stringWithFormat:@"%@", [[[disc objectID] URIRepresentation] absoluteURL]] forKey:@"objectID"];
            [discDict setValue:disc.availableMediaCount forKey:@"availableMedia"];
            
            BOOL isDVD = NO;
            for (Media* m in [disc.allMedia allObjects]) {
                if ([m.type isEqualToString:@"public.dvdmedia"] || [m.type isEqualToString:@"SAMPLE_DATA"]) {
                    isDVD = YES;
                    break;
                }
            }

            [discDict setValue:(isDVD ? @"YES" : @"NO") forKey:@"isDVD"];
            
            [arr addObject:discDict];
        }

        [dict setObject:movie.title forKey:@"title"];
        [dict setObject:arr forKey:@"discs"];
        
        // Send it to the JS
        id a = [webView windowScriptObject];
        [a callWebScriptMethod:@"resetDiscs" withArguments:[NSArray arrayWithObject:[NSString stringWithObjectAsJSON:dict]]];
    }
}

- (void) _resetDiscs:(NSNotification*)notification
{
    [self _setUpDiscLayers];
}

- (Disc*) _discForManagedObjectID:(NSString*)coreDataObjectId
{
    Disc* d = nil;
    
    @try {
        NSURL* coreDataUri = [NSURL URLWithString:coreDataObjectId];
        NSManagedObjectContext* moc = [movie managedObjectContext];
        NSManagedObjectID* objectID = [[moc persistentStoreCoordinator] managedObjectIDForURIRepresentation:coreDataUri];
        d = (Disc*)[moc objectWithID:objectID];
    }
    @catch (NSException* ex) {
        NSLog(@"Error getting Disc object for id %@, exception is: %@", coreDataObjectId, [ex userInfo]);
    }
    
    return d;
}

- (void) _dragInitiated:(NSNotification*)notification
{
    [dropView setHidden:NO];
}

- (void) _dragCompleted:(NSNotification*)notification
{
    [dropView setHidden:YES];
    [[self window] makeFirstResponder:webView];
}

- (void) _combineDidFinish:(NSNotification*)notification
{
    if (self.movie) {
        [self _setUpDiscLayers];
    }
}

- (void) _removeFromSetSheetDidEnd:(NSWindow*)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    if (returnCode == NSRunStoppedResponse) {

        Disc* d = (Disc*)contextInfo;
        
        if (d) {
            Movie* oldMovie = d.movie;
            
            NSManagedObjectContext* moc = [movie managedObjectContext];
            NSEntityDescription* movieEntity = [NSEntityDescription entityForName:@"Movie" inManagedObjectContext:moc];
            Movie* m = [[[Movie alloc] initWithEntity:movieEntity insertIntoManagedObjectContext:moc] autorelease];
            
            m.title = [renameOrBreakOutField stringValue];
            d.movie = m;
            d.number = [NSNumber numberWithInt:1];

            // Now reorder the old movie's discs
            NSArray* oldMovieDiscs = [oldMovie discsInOrder];
            for (int i = 0; i < [oldMovieDiscs count]; i++) {
                Disc* d = [oldMovieDiscs objectAtIndex:i];
                d.number = [NSNumber numberWithInt:(i + 1)];
            }
            
            NSError* error = nil;
            [moc save:&error];
            
            if (error) {
                NSLog(@"Error breaking out a new movie.  Error is: %@", [error userInfo]);
            }
            
            [self _setUpDiscLayers];
        }
    }
}

/*- (void) _renameDiscDidEnd:(NSWindow*)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    if (returnCode == NSRunStoppedResponse) {
        
        Disc* d = (Disc*)contextInfo;
        
        if (d) {
            d.discTitle = [renameOrBreakOutField stringValue];
            
            NSError* error = nil;
            [[movie managedObjectContext] save:&error];
            
            if (error) {
                NSLog(@"Error renaming a disc.  Error is: %@", [error userInfo]);
            }
            
            [self _setUpDiscLayers];
        }
    }
}*/

- (void) _setUpContextMenuItems
{
    renameMenuItem = [[NSMenuItem alloc] initWithTitle:@"Rename disc" action:@selector(_renameDisc:) keyEquivalent:@""];
    removeMenuItem = [[NSMenuItem alloc] initWithTitle:@"Drop from set" action:@selector(_removeFromSet:) keyEquivalent:@""];
    sepMenuItem = [[NSMenuItem separatorItem] retain];
    deleteFromMultiplexItem = [[NSMenuItem alloc] initWithTitle:@"Delete from Multiplex" action:@selector(_deleteFromMultiplex:) keyEquivalent:@""];
}

- (void) _renameDisc:(id)sender
{
    if (!currentCoreDataObjectID) {
        return;
    }
    
    id a = [webView windowScriptObject];
    [a callWebScriptMethod:@"simulateNameDoubleClick" withArguments:[NSArray arrayWithObject:currentCoreDataObjectID]];
}

- (void) _removeFromSet:(id)sender
{
    if (!currentCoreDataObjectID) {
        return;
    }
    
    Disc* d = [self _discForManagedObjectID:currentCoreDataObjectID];
    if (d) {
        [renamePanel prepareForRemoveFromSet];
        
        if (d.discTitle) {
            [renameOrBreakOutField setStringValue:d.discTitle];
        }
        else {
            [renameOrBreakOutField setStringValue:d.movie.title];
        }
        
        [NSApp beginSheet:renamePanel 
           modalForWindow:[self window] 
            modalDelegate:self 
           didEndSelector:@selector(_removeFromSetSheetDidEnd:returnCode:contextInfo:) 
              contextInfo:d];
    }
}

- (void) _deleteFromMultiplex:(id)sender
{
    if (!currentCoreDataObjectID) {
        return;
    }

    Disc* d = [self _discForManagedObjectID:currentCoreDataObjectID];
    if (d) {
        id toSend = nil;
        Movie* m = d.movie;
        
        if ([m.allDiscs count] == 1) {
            toSend = m;
        }
        else {
            toSend = d;
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"MultiplexDeleteMovieOrDisc" object:toSend];
        [[NSRunLoop currentRunLoop] performSelector:@selector(_setUpDiscLayers) target:self argument:nil order:0 modes:[NSArray arrayWithObject:NSDefaultRunLoopMode]];
    }
}

#pragma mark Javascript Calls

- (void) signalIsReady
{
    self.isReady = YES;
    if (self.movie) {
        [self _setUpDiscLayers];
    }
}

- (void) playDisc:(NSString*)coreDataObjectId
{
    Disc* d = [self _discForManagedObjectID:coreDataObjectId];
    if (d) {
        [movieDetailController playDisc:d];
    }
}

- (void) reorderDiscs:(WebScriptObject*)orderArray
{
    for (int i = 0; i < INT32_MAX; i++) {
        id coreDataObjectId = [orderArray webScriptValueAtIndex:i];
        if (coreDataObjectId == [WebUndefined undefined]) {
            break;
        }
        
        Disc* d = [self _discForManagedObjectID:coreDataObjectId];
        if (d) {
            d.number = [NSNumber numberWithInt:(i + 1)];
        }
    }
    
    NSError* error = nil;
    [[movie managedObjectContext] save:&error];
    
    if (error) {
        NSLog(@"Error reordering discs: %@", [error userInfo]);
    }
    
    [self _setUpDiscLayers];
}

- (void) setCurrentCoreDataObjectID:(NSString*)coreDataObjectId
{
    [currentCoreDataObjectID release], currentCoreDataObjectID = nil;
    currentCoreDataObjectID = [coreDataObjectId retain];
}

- (void) renameDisc:(NSString*)coreDataObjectId toName:(NSString*)newName
{
    Disc* d  = [self _discForManagedObjectID:coreDataObjectId];
    
    if (d) {
        d.discTitle = newName;
        
        NSError* error = nil;
        [[d managedObjectContext] save:&error];
        if (error) {
            NSLog(@"Error renaming disc %@ to the new name '%@': %@", coreDataObjectId, newName, [error userInfo]);
        }
    }
}

#pragma mark WebFrameLoadDelegate Methods

- (void)webView:(WebView *)sender didClearWindowObject:(WebScriptObject *)windowObject forFrame:(WebFrame *)frame
{
    // The Javscript is ready
    [windowObject setValue:self forKey:@"mplex"];
}

#pragma mark WebUIDelegate Methods

- (void)webView:(WebView *)sender runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WebFrame *)frame
{
    NSAlert* a = [NSAlert alertWithMessageText:@"Alert" 
                                 defaultButton:@"Ok" 
                               alternateButton:nil 
                                   otherButton:nil 
                     informativeTextWithFormat:message];
    
    [a runModal];
}

- (NSUInteger)webView:(WebView *)sender dragDestinationActionMaskForDraggingInfo:(id <NSDraggingInfo>)draggingInfo
{
    return WebDragDestinationActionNone;
}

- (NSArray *)webView:(WebView *)sender contextMenuItemsForElement:(NSDictionary *)element defaultMenuItems:(NSArray *)defaultMenuItems
{
    if (currentCoreDataObjectID) {
        NSMutableArray* menuItems = [NSMutableArray array];
        [menuItems addObject:renameMenuItem];
       
        if ([movie.allDiscs count] > 1) {
            [menuItems addObject:removeMenuItem];
        }

        [menuItems addObject:sepMenuItem];
        [menuItems addObject:deleteFromMultiplexItem];

        return menuItems;
    }
    else {
        return nil;
    }
}

@end
