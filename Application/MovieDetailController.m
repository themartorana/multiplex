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
    [descriptionWebView setDrawsBackground:NO];

    [descriptionWebView setPreferences:[ApplicationResources movieDescriptionWebPreferences]];
    
    [playButtonView setButtonLayerButtonWithUpState:[ApplicationResources playButton] andDownState:[ApplicationResources playButtonDown]];
    [playButtonView setNotificationNameToPost:@"MultiplexPlayButtonClicked"];
    
    [coverArtImageView bind:@"image" toObject:self withKeyPath:@"movie.boxArt.image" options:[NSDictionary dictionaryWithObjectsAndKeys:(id)[ApplicationResources CGImageFromResource:@"drag-drop-no-image" ofType:@"pdf"], NSNullPlaceholderBindingOption, nil]];
}

- (void) takeControl
{
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(objectContextNeedsSave:) 
                                                 name:NSManagedObjectContextObjectsDidChangeNotification 
                                               object:applicationController.appManagedObjectContext
     ];
}

- (void) relinquishControl
{
    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                    name:NSManagedObjectContextObjectsDidChangeNotification 
                                                  object:applicationController.appManagedObjectContext
     ];    
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
    movie.synopsis = [(id)[[[[[descriptionWebView mainFrame] DOMDocument] documentElement] getElementsByTagName:@"body"] item:0] innerHTML];
}

- (void) setMovie:(Movie*)_movie
{
    [self willChangeValueForKey:@"movie"];
    [movie release];
    movie = [_movie retain];
    [discsView setMovie:movie];
    [self didChangeValueForKey:@"movie"];
}

- (IBAction) startWithMovie:(Movie*)_movie
{
    [self setMovie:_movie];
    [drawerView setContentView:infoPaneView];
    NSString* noSynopsis = @"No description found.  Replace this text to add one.";
    [[descriptionWebView mainFrame] loadHTMLString:movie && movie.synopsis ? movie.synopsis : noSynopsis baseURL:[NSURL URLWithString:@""]];
    
    if (!drawerView.isOpen) {
        [drawerView toggle:self];
    }
}

- (IBAction) refreshMovieInfoFromInternet:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"MultiplexRefreshMovieInfoFromInternet" object:movie];
}

- (void) showHomeTab
{
    [infoTabView selectTabViewItem:[[infoTabView tabViewItems] objectAtIndex:0]];
}

- (void) showDiscsTab
{
    [infoTabView selectTabViewItem:discsTabViewItem];
}

- (BOOL) dragDropTargetView:(DragDropTargetView*)sender allowDragForPasteboard:(NSPasteboard*)pasteBoard
{
    NSArray* fileNames = [pasteBoard propertyListForType:NSFilenamesPboardType];
    if ([fileNames count] > 1) {
        return NO;
    }
    NSError* error = nil;
    NSString* fileType = [[NSWorkspace sharedWorkspace] typeOfFile:[fileNames objectAtIndex:0] error:&error];
    if (error || !fileType) {
        return NO;
    }
    static NSArray* typeIdentifiers = nil;
    if (!typeIdentifiers) {
        typeIdentifiers = (NSArray*)CGImageSourceCopyTypeIdentifiers();
    }
    return [typeIdentifiers containsObject:fileType];
}

- (BOOL) dragDropTargetView:(DragDropTargetView*)sender acceptDragForPasteboard:(NSPasteboard*)pasteBoard
{
    NSString* fileName = [[pasteBoard propertyListForType:NSFilenamesPboardType] objectAtIndex:0];
    CGImageRef image = nil;
    CGImageSourceRef imageSource = CGImageSourceCreateWithURL((CFURLRef)[NSURL fileURLWithPath:fileName], nil);
    if (imageSource) {
        image = CGImageSourceCreateImageAtIndex(imageSource, 0, nil);
        CFRelease(imageSource);
    }
    if (image) {
        NSManagedObjectContext* managedObjectContext = [movie managedObjectContext];
        NSEntityDescription* boxArtEntity = [NSEntityDescription entityForName:@"BoxArt" inManagedObjectContext:managedObjectContext];
        BoxArt* boxArt = [[BoxArt alloc] initWithEntity:boxArtEntity insertIntoManagedObjectContext:managedObjectContext];
        boxArt.image = image;
        movie.boxArt = boxArt;
        CGImageRelease(image);
        return YES;
    } else {
        return NO;
    }
}

@end
