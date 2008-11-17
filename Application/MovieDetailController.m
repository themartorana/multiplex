#import "MovieDetailController.h"
#import "Movie.h"
#import "MovieDetailDiscsView.h"
#import "MultiplexColorFactory.h"
#import "DragDropTargetView.h"
#import "ApplicationResources.h"
#import "ApplicationController.h"
#import "DrawerView.h"
#import "BoxArt.h"
#import "LayerBackedButtonView.h"

#import <WebKit/WebKit.h>

@interface NSScrollView (NSScrollViewWebKitPrivate)
- (void) setAllowsHorizontalScrolling:(BOOL)allow;
- (void) setHorizontalScrollingModeLocked:(BOOL)locked;
- (void) _saveObjectContext;
@end

@implementation MovieDetailController
@synthesize movie;
@synthesize labelColor;
@synthesize valuesAreEditable;

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
    [playButtonView setNotificationNameToPost:@"MultiplexPlayButtonClicked"];
    
    [coverArtImageView bind:@"image" toObject:self withKeyPath:@"movie.boxArt.image" options:[NSDictionary dictionaryWithObjectsAndKeys:(id)[ApplicationResources CGImageFromResource:@"drag-drop-no-image" ofType:@"pdf"], NSNullPlaceholderBindingOption, nil]];
    [coverArtImageEditView bind:@"image" toObject:self withKeyPath:@"movie.boxArt.image" options:[NSDictionary dictionaryWithObjectsAndKeys:(id)[ApplicationResources CGImageFromResource:@"drag-drop-no-image" ofType:@"pdf"], NSNullPlaceholderBindingOption, nil]];
    
    [backgroundBox setCornerRadius:5.0];
    [backgroundBox setFillColor:[NSColor colorWithCalibratedWhite:1.0 alpha:0.1]];
}

- (void) takeControl
{
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(objectContextNeedsSave:) 
                                                 name:NSManagedObjectContextObjectsDidChangeNotification 
                                               object:applicationController.appManagedObjectContext
     ];
}

- (BOOL) relinquishControl
{
    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                    name:NSManagedObjectContextObjectsDidChangeNotification 
                                                  object:applicationController.appManagedObjectContext
     ];
    
    return YES;
}

- (IBAction) selectTab:(id)sender
{
    [infoTabView selectTabViewItemAtIndex:[sender selectedSegment]];
}

- (void) objectContextNeedsSave:(NSNotification*)notification
{
    [[NSRunLoop currentRunLoop] performSelector:@selector(_saveObjectContext) target:self argument:nil order:0 modes:[NSArray arrayWithObject:NSDefaultRunLoopMode]];
}

- (void) _saveObjectContext
{
    NSError* error = nil;
    [[movie managedObjectContext] save:&error];
    
    if (error) {
        NSLog(@"%@", [error userInfo]);
        NSAssert(FALSE, @"ERROR SAVING DATA!");
    }
}

- (void) webViewDidEndEditing:(NSNotification*)notification
{
    NSString* noSynopsis = @"No description found. Click on the \"Description\" tab to enter one.";
    movie.synopsis = [(id)[[[[[descriptionWebView mainFrame] DOMDocument] documentElement] getElementsByTagName:@"body"] item:0] innerHTML];
    [[overviewWebView mainFrame] loadHTMLString:movie && movie.synopsis ? movie.synopsis : noSynopsis baseURL:[NSURL URLWithString:@""]];
}

- (void) setMovie:(Movie*)_movie
{
    [self willChangeValueForKey:@"movie"];
    [movie release];
    movie = [_movie retain];
    [discsView setMovie:movie];
    [self didChangeValueForKey:@"movie"];
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

- (IBAction) startWithMovie:(Movie*)_movie
{
    [self setMovie:_movie];
    [drawerView setContentView:infoPaneView];
    NSString* noSynopsis = @"No description found. Click on the \"Description\" tab to enter one.";
    NSString* noSynopsisEdit = @"No description found. Replace this text to add one.";
    [[descriptionWebView mainFrame] loadHTMLString:movie && movie.synopsis ? movie.synopsis : noSynopsisEdit baseURL:[NSURL URLWithString:@""]];
    [[overviewWebView mainFrame] loadHTMLString:movie && movie.synopsis ? movie.synopsis : noSynopsis baseURL:[NSURL URLWithString:@""]];
    
    if (!drawerView.isOpen) {
        [drawerView toggle:self];
    }
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

@end
