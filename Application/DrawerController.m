#import "DrawerController.h"
#import "DrawerView.h"
#import "Movie.h"
#import "Activity.h"
#import "ApplicationResources.h"
#import "CoverArtImageView.h"
#import "BoxArt.h"
#import "InfoPaneFormController.h"

#import "AmazonQuery.h"
#import "ImageQuery.h"

#import <DiscIdentKit/DiscIdentKit.h>
#import <WebKit/WebKit.h>
#import <Toolkit/Toolkit.h>

@interface DrawerController (Private)
- (void) changeDrawerView:(BOOL)isOpen;
- (void) showResultAtIndex:(int)index;
@end


@implementation DrawerController

- (DrawerController*) init
{
    if (self = [super init]) {
        resultIndex = -1;
    }
    
    return self;
}

- (void) awakeFromNib
{
    [self bind:@"selectedMovie" toObject:movies withKeyPath:@"selection.self" options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:NSAllowsNullArgumentBindingOption]];
    [drawerView addObserver:self forKeyPath:@"isOpen" options:NSKeyValueObservingOptionNew context:nil];
    
    [searchResultsDescriptionWebView setDrawsBackground:NO];
    [searchResultsDescriptionWebView setPreferences:[ApplicationResources movieDescriptionWebPreferences]];
    
    [searchResultsBoxArt bind:@"image" toObject:self withKeyPath:@"selectedMovie.boxArt.image" options:[NSDictionary dictionaryWithObjectsAndKeys:(id)[ApplicationResources CGImageFromResource:@"drag-drop-no-image" ofType:@"pdf"], NSNullPlaceholderBindingOption, nil]];
}

- (void) dealloc
{
    [selectedMovie release];
    [super dealloc];
}

- (void) setSelectedMovie:(Movie*)_selectedMovie
{   
    if (selectedMovie != _selectedMovie) {
        [selectedMovie release];
        selectedMovie = [_selectedMovie retain];
        [self changeDrawerView:drawerView.isOpen];
    }
}

- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
    if (object == drawerView) {
        if ([@"isOpen" isEqualToString:keyPath]) {
            BOOL isOpen = [(NSNumber*)[object valueForKeyPath:keyPath] boolValue];
            [self changeDrawerView:isOpen];
        }
    }
}

- (void) changeDrawerView:(BOOL)isOpen
{
    if (!isOpen) {
        [drawerView setContentView:nil];
    } 
    else if ([selectedMovie.gtin length] > 0 || selectedMovie.metadataAcceptedDate != nil) {
        [drawerView setContentView:movieInfoView];
    } 
    else if (selectedMovie) {
        [drawerView setContentView:searchForMovieView];
    } 
    else {
        [drawerView setContentView:noMovieSelectedView];
    }
}

- (IBAction) skipEnterUPC:(id)sender
{
    [drawerView setContentView:movieInfoView];
}

#pragma mark Lookup Methods

- (IBAction) lookUpUPC:(id)sender
{
    Activity* activityUPCLookup = [Activity activityWithName:@"Looking up UPC code" userInfo:nil];
    
    [drawerView setContentView:searchingView];
    
    NSMutableString* ean = [NSMutableString stringWithString:[upcTextField stringValue]];
    while ([ean length] < 13) {
        [ean insertString:@"0" atIndex:0];
    }
    
    amazonQuery = [[AmazonQuery amazonQueryWithAccessKey:kAmazonAccessKey ean:ean delegate:self userInfo:activityUPCLookup startImmediately:YES] retain];
}

- (IBAction) lookUpTitle:(id)sender
{
    Activity* activityTitleLookup = [Activity activityWithName:@"Looking up title" userInfo:nil];

    [drawerView setContentView:searchingView];
    
    NSMutableString* title = [NSMutableString stringWithString:[titleTextField stringValue]];
    amazonQuery = [[AmazonQuery amazonQueryWithAccessKey:kAmazonAccessKey titleKeywords:title delegate:self userInfo:activityTitleLookup startImmediately:YES] retain];
}

- (IBAction) selectResult:(id)sender
{
    NSError* error = nil;
    [[selectedMovie managedObjectContext] save:&error];
    
    if (error) {
        NSLog(@"%@", [error userInfo]);
        NSAssert(FALSE, @"ERROR SAVING DATA!");
    }
    
    [drawerView setContentView:movieInfoView];
    [formController showHomeTab];
}

- (IBAction) showNextResult:(id)sender
{
    resultIndex++;
    if (resultIndex + 1 > [amazonQueryResults count]) {
        resultIndex--;
        return;
    }
    else {
        [self showResultAtIndex:resultIndex];
    }    
}

- (IBAction) showPreviousResult:(id)sender
{
    resultIndex--;
    if (resultIndex < 0) {
        resultIndex = -1;
        return;
    } 
    else {
        [self showResultAtIndex:resultIndex];
    }
}

- (IBAction) backToSearch:(id)sender
{
    [[selectedMovie managedObjectContext] rollback];
    resultIndex = -1;
    [drawerView setContentView:searchForMovieView];
}

- (void) showResultAtIndex:(int)index
{
    if ([drawerView contentView] != searchResultsView) {
        [drawerView setContentView:searchResultsView];
    }
    
    NSDictionary* resultAtIndex = [amazonQueryResults objectAtIndex:index];
    
    // TODO: NO BOX ART??
    if ([resultAtIndex objectForKey:@"_coverImageURL"]) {
        NSURL* imageUrl = [NSURL URLWithString:[resultAtIndex objectForKey:@"_coverImageURL"]];
        imageQuery = [[ImageQuery imageQueryWithURL:imageUrl delegate:self userInfo:nil startImmediately:YES] retain];
    }
    
    if (resultAtIndex) {
        // Start loading in information
        selectedMovie.title = [resultAtIndex objectForKey:@"title"];
        selectedMovie.aspectRatio = [resultAtIndex objectForKey:@"aspectRatio"];
        //selectedMovie.genre = [resultAtIndex objectForKey:@"Genre"];
        selectedMovie.metadataAcceptedDate = [NSDate date];
        selectedMovie.releaseDate = [resultAtIndex objectForKey:@"releaseDate"] ? [NSDate dateFromShortDateString:[resultAtIndex objectForKey:@"releaseDate"]] : nil;
        selectedMovie.rating = [resultAtIndex objectForKey:@"audienceRating"];
        selectedMovie.regionCode = [resultAtIndex objectForKey:@"regionCode"];
        selectedMovie.review = [resultAtIndex objectForKey:@"review"];
        selectedMovie.runningTime = [resultAtIndex objectForKey:@"runningTime"];
        selectedMovie.studio = [resultAtIndex objectForKey:@"studio"];
        selectedMovie.synopsis = [resultAtIndex objectForKey:@"synopsis"];
        selectedMovie.theatricalReleaseDate = [resultAtIndex objectForKey:@"theatricalReleaseDate"] ? [NSDate dateFromShortDateString:[resultAtIndex objectForKey:@"theatricalReleaseDate"]] : nil;
        selectedMovie.productionYear = selectedMovie.theatricalReleaseDate ? [NSNumber numberWithInt:[[selectedMovie.theatricalReleaseDate descriptionWithCalendarFormat:@"%Y" timeZone:nil locale:nil] intValue]] : nil;
        
        // Set the GTIN?
        if (AmazonQueryTypeEAN == amazonQuery.queryType) {
            // TODO: Push back to DiscIdent
            
            NSMutableString* gtin = [NSMutableString stringWithString:[upcTextField stringValue]];
            while ([gtin length] < 14) {
                [gtin insertString:@"0" atIndex:0];
            }
            selectedMovie.gtin = gtin;
        }
        
        NSString* resultCount = [NSString stringWithFormat:@"%d of %d", index + 1, [amazonQueryResults count]];
        [searchResultsRecordCount setStringValue:resultCount];
        [[searchResultsDescriptionWebView mainFrame] loadHTMLString:selectedMovie.synopsis baseURL:[NSURL URLWithString:@""]];
    }
}

- (void) showNoResultsSheet
{
    NSString* upc = [upcTextField stringValue];
    NSString* message = nil;
    
    if (upc && [upc length]) {
        message = [NSString stringWithFormat:@"No results were found for the UPC code %@", upc];
    }
    else {
        message = @"No results were found.";
    }
    NSAlert* alert = [NSAlert alertWithMessageText:message defaultButton:@"Ok" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Please check your information and try again.."];
    [alert beginSheetModalForWindow:[upcTextField window] modalDelegate:nil didEndSelector:nil contextInfo:nil];    
}

#pragma mark "AmazonQuery delegate methods"

- (void) amazonQuery:(AmazonQuery*)query didFailWithError:(NSError*)error userInfo:(id)userInfo
{
    [(Activity*)userInfo terminate];
    
    NSLog(@"AMAZON QUERY ERROR: %@", error);
    [drawerView setContentView:searchForMovieView];
    [self showNoResultsSheet];
}

- (void) amazonQuery:(AmazonQuery*)query didReceiveResponse:(NSArray*)response userInfo:(id)userInfo
{    
    [(Activity*)userInfo terminate];

    if (![response count]) {
        [self showNoResultsSheet];
    }
    else {
        if (amazonQueryResults) {
            [amazonQueryResults release];
            amazonQueryResults = nil;
        }
        amazonQueryResults = [response retain];
        resultIndex = 0;
        [self showResultAtIndex:0];
    }
}

#pragma mark "ImageQuery delegate methods"

- (void) imageQuery:(ImageQuery*)query didReceiveImageSource:(CGImageSourceRef)imageSource userInfo:(id)userInfo;
{
    // Set the box art
    BoxArt* boxArt = nil;
    if (selectedMovie.boxArt) {
        boxArt = selectedMovie.boxArt;
    }
    else {
        NSManagedObjectContext* managedObjectContext = [selectedMovie managedObjectContext];
        NSEntityDescription* boxArtEntity = [NSEntityDescription entityForName:@"BoxArt" inManagedObjectContext:managedObjectContext];
        boxArt = [[BoxArt alloc] initWithEntity:boxArtEntity insertIntoManagedObjectContext:managedObjectContext];
        selectedMovie.boxArt = boxArt;
    }
    
    CGImageRef image = CGImageSourceCreateImageAtIndex(imageSource, 0, (CFDictionaryRef)[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], kCGImageSourceCreateThumbnailFromImageAlways, nil]);

    boxArt.state = @"Loaded";
    boxArt.url = [[query URL] absoluteString];
    boxArt.image = image;

    CGImageRelease(image);
}


@end
