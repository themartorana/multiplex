#import "MovieDetailController.h"
#import "Movie.h"
#import "InfoPaneDiscsView.h"
#import "MultiplexColorFactory.h"
#import "DragDropTargetView.h"
#import "ApplicationResources.h"
#import "DrawerView.h"
#import "BoxArt.h"
#import "LayerBackedButtonView.h"
#import "TextView.h"

#import <WebKit/WebKit.h>

@interface NSScrollView (NSScrollViewWebKitPrivate)
- (void) setAllowsHorizontalScrolling:(BOOL)allow;
- (void) setHorizontalScrollingModeLocked:(BOOL)locked;
@end

@implementation MovieDetailController

@synthesize movie;
@synthesize labelColor;
@synthesize valuesAreEditable;

- (MovieDetailController*) init
{
    if (self = [super init]) {
        labelColor = [MultiplexColorFactory multiplexYellowOrange];
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
    [discTitleView bind:@"text" toObject:self withKeyPath:@"movie.title" options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:NSAllowsNullArgumentBindingOption]];
}

- (void) setMovie:(Movie*)_movie
{
    if (movie != _movie) {
        [self willChangeValueForKey:@"movie"];
        [movie release];
        movie = [_movie retain];
        [[descriptionWebView mainFrame] loadHTMLString:movie ? movie.synopsis : @"" baseURL:[NSURL URLWithString:@""]];
        [self didChangeValueForKey:@"movie"];
    }
}

- (void) webViewDidEndEditing:(NSNotification*)notification
{
    movie.synopsis = [(id)[[[[[descriptionWebView mainFrame] DOMDocument] documentElement] getElementsByTagName:@"body"] item:0] innerHTML];
}

- (void) tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
#if 0
    if (tabViewItem == discsTabViewItem) {
        [bigPlayButtonView setHidden:YES];
    } else {
        [bigPlayButtonView setHidden:NO];
    }
#endif
}

- (IBAction) startWithMovie:(Movie*)_movie
{
    [self setMovie:_movie];
    [drawerView setContentView:infoPaneView];
    [infoTabView selectTabViewItem:[[infoTabView tabViewItems] objectAtIndex:0]];
}


- (void) showHomeTab
{
    [[descriptionWebView mainFrame] loadHTMLString:movie ? movie.synopsis : @"" baseURL:[NSURL URLWithString:@""]];
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
