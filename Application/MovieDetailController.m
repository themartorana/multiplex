#import "MovieDetailController.h"
#import "Movie.h"
#import "MovieDetailDiscsView.h"
#import "MultiplexColorFactory.h"
#import "DragDropTargetView.h"
#import "ApplicationResources.h"
#import "ApplicationController.h"
#import "DrawerView.h"
#import "BoxArt.h"
#import "MovieURL.h"
#import "Disc.h"
#import "Media.h"
#import "Participant.h"
#import "LayerBackedButtonView.h"

#import <WebKit/WebKit.h>
#import <Toolkit/Toolkit.h>

@interface NSScrollView (NSScrollViewWebKitPrivate)
- (void) setAllowsHorizontalScrolling:(BOOL)allow;
- (void) setHorizontalScrollingModeLocked:(BOOL)locked;
- (void) _saveObjectContext;
@end

@interface MovieDetailController (Private)
- (MovieURL*) getAmazonURL;
- (void) addParticipant:(BOOL)isActor;
- (BOOL) setBurnPossible;
@end

@implementation MovieDetailController
@synthesize movie;
@synthesize labelColor;
@synthesize valuesAreEditable;
@synthesize isAvailableFromAmazon;
@synthesize isBurnPossible;

- (id) initWithApplicationController:(ApplicationController*)_applicationController drawerView:(DrawerView*)_drawerView;
{
    NSAssert(_applicationController, @"wtf?");
    NSAssert(_drawerView, @"wtf?");
    if (self = [super init]) {
        applicationController = [_applicationController retain];
        drawerView = [_drawerView retain];
        labelColor = [MultiplexColorFactory multiplexYellowOrange];
        if (![NSBundle loadNibNamed:@"MovieDetail" owner:self]) {
            return nil;
        }
    }
    
    [self bind:@"movie" toObject:applicationController withKeyPath:@"selectedMovie" options:nil];
    
    return self;
}

- (void) awakeFromNib
{
    // Set up the appropriate things for the web view
    [descriptionWebView setEditingDelegate:self];
    [descriptionWebView setFrameLoadDelegate:self];
    [descriptionWebView setEditable:YES];
    [descriptionWebView setDrawsBackground:YES];
    //[descriptionWebView setPreferences:[ApplicationResources movieDescriptionWebPreferences]];
    
    [overviewWebView setFrameLoadDelegate:self];
    [overviewWebView setEditable:NO];
    [overviewWebView setDrawsBackground:NO];
    [overviewWebView setPreferences:[ApplicationResources movieDescriptionWebPreferences]];
    
    [playButtonView setButtonLayerButtonWithUpState:[ApplicationResources playButton] andDownState:[ApplicationResources playButtonDown]];
    [playButtonView setNotificationNameToPost:@"MultiplexPlayMovie"];
    
    [coverArtImageView bind:@"image" toObject:self withKeyPath:@"movie.boxArt.image" options:[NSDictionary dictionaryWithObjectsAndKeys:(id)[ApplicationResources CGImageFromResource:@"drag-drop-no-image" ofType:@"pdf"], NSNullPlaceholderBindingOption, nil]];
    [coverArtImageEditView bind:@"image" toObject:self withKeyPath:@"movie.boxArt.image" options:[NSDictionary dictionaryWithObjectsAndKeys:(id)[ApplicationResources CGImageFromResource:@"drag-drop-no-image" ofType:@"pdf"], NSNullPlaceholderBindingOption, nil]];
    
    [backgroundBox setCornerRadius:5.0];
    [backgroundBox setFillColor:[NSColor colorWithCalibratedWhite:1.0 alpha:0.1]];
    
    [editImageBox setCornerRadius:5.0];
    [editImageBox setFillColor:[NSColor colorWithCalibratedWhite:0.6 alpha:0.5]];
    
    NSSortDescriptor* sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
    [actorsArrayController setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    [crewArrayController setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    [sortDescriptor release];
}

- (void) takeControl
{
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(_objectContextDidChange:) 
                                                 name:NSManagedObjectContextObjectsDidChangeNotification 
                                               object:applicationController.appManagedObjectContext
     ];
    
    [drawerView setContentView:infoPaneView];
    
    NSString* noSynopsis = @"No description found. Replace this text to add one.";
    [[descriptionWebView mainFrame] loadHTMLString:movie && movie.synopsis ? movie.synopsis : noSynopsis baseURL:[NSURL URLWithString:@""]];
    [[overviewWebView mainFrame] loadHTMLString:movie ? [self generateDescriptionHtmlString] : @"" baseURL:[NSURL URLWithString:@""]];
    
    if (!drawerView.isOpen) {
        [drawerView toggle:self];
    }    
}

- (void) pleaseRelinquishControlAndApprove:(id<ExecuteTokenProtocol>)executeToken
{
    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                    name:NSManagedObjectContextObjectsDidChangeNotification 
                                                  object:applicationController.appManagedObjectContext
     ];
    
    [executeToken approve];
}

- (IBAction) selectTab:(id)sender
{
    [infoTabView selectTabViewItemAtIndex:[sender selectedSegment]];
}

- (void) _objectContextDidChange:(NSNotification*)notification
{
    NSSet* updated = [notification.userInfo objectForKey:@"updated"];
    NSManagedObjectContext* managedObjectContext = notification.object;
    BOOL performSave = NO;
    
    if ([managedObjectContext hasChanges]) {
        if (updated) {
            if ([updated containsObject:movie] && [[updated allObjects] count] == 1) {
                NSDictionary* changedValues = movie.changedValues;
                int count = [changedValues count];
                NSDate* metadataAcceptedDate = [changedValues objectForKey:@"metadataAcceptedDate"];
                
                /*  If just the metadataAcceptedDate changed, then don't bother 
                 *  doing a save.
                 */
                if ((count > 1) || (count == 1 && metadataAcceptedDate == nil)) {
                    performSave = YES;
                }
            }
            else {
                performSave = YES;
            }            
        }
    }
    
    if (performSave) {
        [self performSelectorOnMainThread:@selector(_saveObjectContext) withObject:nil waitUntilDone:NO];
    }
}

- (void) _saveObjectContext
{
    NSError* error = nil;
    if (![movie isDeleted]) {
        movie.metadataAcceptedDate = [NSDate date];
    }
    else {
        [applicationController setSelectedMovie:nil];
    }
        
    [[movie managedObjectContext] save:&error];
    
    if (error) {
        NSLog(@"%@", [error userInfo]);
    }
}

- (void) webViewDidEndEditing:(NSNotification*)notification
{
    movie.synopsis = [(id)[[[[[descriptionWebView mainFrame] DOMDocument] documentElement] getElementsByTagName:@"body"] item:0] innerHTML];
    [[overviewWebView mainFrame] loadHTMLString:[self generateDescriptionHtmlString] baseURL:[NSURL URLWithString:@""]];
}

- (void) setMovie:(Movie*)_movie
{
    [self willChangeValueForKey:@"movie"];
    [movie release];
    movie = [_movie retain];
    [discsView setMovie:movie];
    [self didChangeValueForKey:@"movie"];
    
    if ([self getAmazonURL]) {
        [self setIsAvailableFromAmazon:YES];
    }
    else {
        [self setIsAvailableFromAmazon:NO];
    }
    
    self.isBurnPossible = [self setBurnPossible];
}

- (MovieURL*) getAmazonURL
{
    if (!movie) {
        return NO;
    }
    
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

- (NSPredicate*) actorsFilter
{
    NSPredicate* actorsFilterPredicate = [NSPredicate predicateWithFormat:
                                        @"%K == %@", @"type", @"actor"];
    return actorsFilterPredicate;
}

- (NSPredicate*) crewFilter
{
    NSPredicate* crewFilterPredicate = [NSPredicate predicateWithFormat:
                                        @"%K != %@", @"type", @"actor"];
    return crewFilterPredicate;
}

- (NSSortDescriptor*) discsSortDescriptor
{
    return [NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"number" ascending:YES]];;
}

- (BOOL) setBurnPossible
{
    BOOL toastIsAvailable = NO;
    
    // Determine if we have a proper version of toast
    NSString* s = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:@"com.roxio.Toast"];
    if (s && ![s isEqualToString:@""]) {
        NSBundle* b = [NSBundle bundleWithPath:s];
        if (b && [[b version] intValue] >= 9) {
            toastIsAvailable = YES;
        }
    }
    
    BOOL hasLocalMedia = NO;
    for (Disc* d in movie.allDiscs) {
        if ([d.localMediaCount intValue] > 0) {
            hasLocalMedia = YES;
            break;
        }
    }
    
    if (toastIsAvailable && hasLocalMedia) {
        return YES;
    }
    return NO;
}

- (IBAction) refreshMovieInfoFromInternetByUPC:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"MultiplexRefreshMovieInfoFromInternetByUPC" object:movie];
}

- (IBAction) refreshMovieInfoFromInternetByTitle:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"MultiplexRefreshMovieInfoFromInternetByTitle" object:movie];
}

- (IBAction) deleteCoverArtForMovie:(id)sender
{
    BoxArt* b = [movie boxArt];
    if (b) {
        NSManagedObjectContext* c = [b managedObjectContext];
        
        [c deleteObject:b];
        
        NSError* error = nil;
        [c save:&error];
        
        if (error) {
            NSLog(@"%@", error);
        }
    }
}

- (IBAction) deleteMetadataForMovie:(id)sender
{
    
}

- (IBAction) deleteMovie:(id)sender
{
    Movie* m = movie;
    
    [applicationController setSelectedMovie:nil];
    
    NSManagedObjectContext* c = [applicationController appManagedObjectContext];
    [c deleteObject:m];
}

- (IBAction) buyFromAmazon:(id)sender
{
    MovieURL* url = [self getAmazonURL];
    NSString* urlString = url.url;
    NSURL* nsurl = [NSURL URLWithString:urlString];
    
    [[NSWorkspace sharedWorkspace] openURL:nsurl];
}

- (IBAction) playSelectedMovie:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"MultiplexPlayMovie" object:nil];
}

- (IBAction) playDisc:(id)obj
{
    if ([obj isKindOfClass:[Disc class]]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"MultiplexPlayDisc" object:obj];
    }
}

- (IBAction) addActor:(id)sender
{
    [self addParticipant:YES];
}

- (IBAction) addCrewMember:(id)sender
{
    [self addParticipant:NO];
}

- (void) _burnApproved:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo;
{
    if (returnCode == NSAlertDefaultReturn) {
        Media* m = (Media*)contextInfo;
        
        NSString* s = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:@"com.roxio.Toast"];
        [[NSWorkspace sharedWorkspace] openFile:m.pathToFile withApplication:s];
    }
}

- (IBAction) burnWithToast:(id)sender
{
    Media* m = nil;
    
    // Get the media
    for (Disc* d in movie.allDiscs) {
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

- (void) addParticipant:(BOOL)isActor
{
    NSEntityDescription* participantEntity = [NSEntityDescription entityForName:@"Participant" inManagedObjectContext:[applicationController appManagedObjectContext]];
    Participant* p = [[Participant alloc] initWithEntity:participantEntity insertIntoManagedObjectContext:[applicationController appManagedObjectContext]];
    
    p.movie = movie;
    p.name = @"Name";

    NSArrayController* ac = nil;
    NSTableView* tv = nil;
    
    if (isActor) {
        p.position = @"Role";
        p.type = @"actor";
        
        ac = actorsArrayController;
        tv = actorsTableView;
    }
    else {
        p.position = @"Position";
        p.type = @"crew";
        
        ac = crewArrayController;
        tv = crewTableView;
    }
    
    int pos = [[ac arrangedObjects] indexOfObject:p];
    [tv selectRowIndexes:[NSIndexSet indexSetWithIndex:pos] byExtendingSelection:NO];
    [tv editColumn:0 row:pos withEvent:nil select:YES];    
}

- (void) showHomeTab
{
    int index = [[infoTabView tabViewItems] indexOfObject:overviewTabViewItem];
    [tabSelector setSelectedSegment:index];
    [infoTabView selectTabViewItemAtIndex:index];
}

- (void) showDiscsTab
{
    int index = [[infoTabView tabViewItems] indexOfObject:discsTabViewItem];
    [tabSelector setSelectedSegment:index];
    [infoTabView selectTabViewItemAtIndex:index];
}

- (NSArray*) registeredDragTypesForDragDropTargetView:(DragDropTargetView*)sender
{
    return [NSArray arrayWithObjects:NSURLPboardType, NSFilenamesPboardType, NSStringPboardType, nil];
}

- (BOOL) dragDropTargetView:(DragDropTargetView*)sender allowDragForPasteboard:(NSPasteboard*)pasteBoard
{
    NSString* type = [pasteBoard availableTypeFromArray:[NSArray arrayWithObjects:NSURLPboardType, NSFilenamesPboardType, NSStringPboardType, nil]];
    if ([NSFilenamesPboardType isEqualToString:type]) {
        NSString* fileName = [[pasteBoard propertyListForType:NSFilenamesPboardType] objectAtIndex:0];
        NSError* error = nil;
        NSString* fileType = [[NSWorkspace sharedWorkspace] typeOfFile:fileName error:&error];
        if (error || !fileType) {
            return NO;
        }
        static NSArray* typeIdentifiers = nil;
        if (!typeIdentifiers) {
            typeIdentifiers = (NSArray*)CGImageSourceCopyTypeIdentifiers();
        }
        return [typeIdentifiers containsObject:fileType];
    } else if ([NSURLPboardType isEqualToString:type]) {
        return YES;
    } else if ([NSStringPboardType isEqualToString:type]) {
        NSString* urlAsString = [[pasteBoard propertyListForType:NSURLPboardType] objectAtIndex:0];
        NSURL* url = [NSURL URLWithString:urlAsString];
        return url != nil;
    } else {
        return NO;
    }
}

- (BOOL) dragDropTargetView:(DragDropTargetView*)sender acceptDragForPasteboard:(NSPasteboard*)pasteBoard
{
    NSURL* url = nil;
    NSString* item = nil;
    if (nil != (item = [[pasteBoard propertyListForType:NSFilenamesPboardType] objectAtIndex:0])) {
        url = [NSURL fileURLWithPath:item];
    } else if (nil != (item = [[pasteBoard propertyListForType:NSURLPboardType] objectAtIndex:0])) {
        url = [NSURL URLWithString:item];
    }


    if (url) {
        CGImageRef image = nil;
        CGImageSourceRef imageSource = CGImageSourceCreateWithURL((CFURLRef)url, nil);
        if (imageSource) {
            image = CGImageSourceCreateImageAtIndex(imageSource, 0, nil);
            CFRelease(imageSource);
        }
        if (image) {
            NSManagedObjectContext* managedObjectContext = [movie managedObjectContext];
            NSEntityDescription* boxArtEntity = [NSEntityDescription entityForName:@"BoxArt" inManagedObjectContext:managedObjectContext];
            BoxArt* boxArt = [[BoxArt alloc] initWithEntity:boxArtEntity insertIntoManagedObjectContext:managedObjectContext];
            boxArt.image = image;
            boxArt.url = [url absoluteString];
            boxArt.state = @"Loaded";
            movie.boxArt = boxArt;
            CGImageRelease(image);
            return YES;
        } else {
            return NO;
        }
    } else {
        return NO;
    }
}

- (NSString*) generateDescriptionHtmlString
{
    NSString* noSynopsis = @"No description found. Click on the \"Description\" tab to enter one.";
    
    if (!movie) {
        return noSynopsis;
    }
    else {
        NSMutableString* htmlString = [NSMutableString string];

        // Set up the synopsis
        [htmlString appendString:@"<div id=\"description_synopsis_info\">"];
        [htmlString appendFormat:@"<div id=\"description_synopsis_header\">%@</div>", @"Synopsis"];
        [htmlString appendFormat:@"<div id=\"description_synopsis\">%@</div>", movie.synopsis ? movie.synopsis : noSynopsis];
        [htmlString appendString:@"</div>"];
        
        [htmlString appendString:@"<div id=\"description_secondary_info\">"];
        
        // Running time
        if (movie.runningTime) {
            [htmlString appendFormat:@"<div id=\"description_run_time_header\">%@</div>", @"Running Time"];
            [htmlString appendFormat:@"<div id=\"description_run_time\">%@ %@</div>", [movie.runningTime stringValue], @"minutes"];
        }
        
        // Production year
        if (movie.productionYear) {
            [htmlString appendFormat:@"<div id=\"description_production_year_header\">%@</div>", @"Produced in"];
            [htmlString appendFormat:@"<div id=\"description_production_year\">%@</div>", [movie.productionYear stringValue]];
        }
        
        // Participants
        if ([movie.allParticipants count]) {
            NSSortDescriptor* sort = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
            
            NSArray* participantsInOrder = [[movie.allParticipants allObjects] sortedArrayUsingDescriptors:[NSArray arrayWithObject:sort]];

            // Director
            NSMutableString* directors = [NSMutableString string];
            for (Participant* p in participantsInOrder) {                
                if (p.type && [[p.type lowercaseString] isEqualToString:@"director"]) {
                    if ([directors length]) {
                        [directors appendString:@"<br />"];
                    }
                    [directors appendString:p.name];
                }
            }
            if ([directors length]) {
                [htmlString appendFormat:@"<div id=\"description_directors_header\">%@</div>", [directors rangeOfString:@"<br />"].location != NSNotFound ? @"Directors" : @"Director"];
                [htmlString appendFormat:@"<div id=\"description_directors\">%@</div>", directors];
            }
            
        
            // Actors
            NSMutableString* actors = [NSMutableString string];
            for (Participant* p in participantsInOrder) {                
                if (p.type && [[p.type lowercaseString] isEqualToString:@"actor"]) {
                    if ([actors length]) {
                        [actors appendString:@"<br />"];
                    }
                    [actors appendFormat:p.name];
                }
            }            
            if ([actors length]) {
                [htmlString appendFormat:@"<div id=\"description_actors_header\">%@</div>", @"Cast"];
                [htmlString appendFormat:@"<div id=\"description_actors\">%@</div>", actors];
            }
        }
        
        [htmlString appendString:@"</div>"];
        
        return htmlString;
    }
}

@end
