#import "InfoLookupController.h"
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

static NSString* const kAmazonAccessKey = @"01Y2NSCMDJ3VJXTCBTR2";

@interface InfoLookupController (Private)
- (void) changeDrawerView:(BOOL)isOpen;
- (void) showResultAtIndex:(int)index;
@end


@implementation InfoLookupController
@synthesize movie;

- (void) awakeFromNib
{
    [searchResultsDescriptionWebView setDrawsBackground:NO];
    [searchResultsDescriptionWebView setPreferences:[ApplicationResources movieDescriptionWebPreferences]];
    [searchResultsBoxArt bind:@"image" toObject:self withKeyPath:@"movie.boxArt.image" options:[NSDictionary dictionaryWithObjectsAndKeys:(id)[ApplicationResources CGImageFromResource:@"drag-drop-no-image" ofType:@"pdf"], NSNullPlaceholderBindingOption, nil]];
}

- (void) dealloc
{
    [movie release];
    [super dealloc];
}

- (void) beginLookupForMovie:(Movie*)_movie
{
    resultIndex = 0;
    self.movie = _movie;
    [drawerView setContentView:searchForMovieView];
}

- (IBAction) skipEnterUPC:(id)sender
{
    [drawerController showInfoPanelAndSelectHomeTab:nil];
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
    [[movie managedObjectContext] save:&error];
    
    if (error) {
        NSLog(@"%@", [error userInfo]);
        NSAssert(FALSE, @"ERROR SAVING DATA!");
    }
    
    [drawerController showInfoPanelAndSelectHomeTab:nil];
}

- (IBAction) showNextResult:(id)sender
{
    resultIndex++;
    if (resultIndex >= [amazonQueryResults count]) {
        resultIndex = 0;
    }
    [self showResultAtIndex:resultIndex];
}

- (IBAction) showPreviousResult:(id)sender
{
    resultIndex--;
    if (resultIndex < 0) {
        resultIndex = [amazonQueryResults count] - 1;
    } 
    [self showResultAtIndex:resultIndex];
}

- (IBAction) backToSearch:(id)sender
{
    [[movie managedObjectContext] rollback];
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
    } else {
        movie.boxArt = nil;
    }
    
    if (resultAtIndex) {
        // Start loading in information
        movie.title = [resultAtIndex objectForKey:@"title"];
        movie.aspectRatio = [resultAtIndex objectForKey:@"aspectRatio"];
        //selectedMovie.genre = [resultAtIndex objectForKey:@"Genre"];
        movie.metadataAcceptedDate = [NSDate date];
        movie.releaseDate = [resultAtIndex objectForKey:@"releaseDate"] ? [NSDate dateFromShortDateString:[resultAtIndex objectForKey:@"releaseDate"]] : nil;
        movie.rating = [resultAtIndex objectForKey:@"audienceRating"];
        movie.regionCode = [resultAtIndex objectForKey:@"regionCode"];
        movie.review = [resultAtIndex objectForKey:@"review"];
        movie.runningTime = [resultAtIndex objectForKey:@"runningTime"];
        movie.studio = [resultAtIndex objectForKey:@"studio"];
        movie.synopsis = [resultAtIndex objectForKey:@"synopsis"];
        movie.theatricalReleaseDate = [resultAtIndex objectForKey:@"theatricalReleaseDate"] ? [NSDate dateFromShortDateString:[resultAtIndex objectForKey:@"theatricalReleaseDate"]] : nil;
        movie.productionYear = movie.theatricalReleaseDate ? [NSNumber numberWithInt:[[movie.theatricalReleaseDate descriptionWithCalendarFormat:@"%Y" timeZone:nil locale:nil] intValue]] : nil;
        
        // Set the GTIN?
        if (AmazonQueryTypeEAN == amazonQuery.queryType) {
            // TODO: Push back to DiscIdent
            
            NSMutableString* gtin = [NSMutableString stringWithString:[upcTextField stringValue]];
            while ([gtin length] < 14) {
                [gtin insertString:@"0" atIndex:0];
            }
            movie.gtin = gtin;
        }
        
        NSString* resultCount = [NSString stringWithFormat:@"%d of %d", index + 1, [amazonQueryResults count]];
        [searchResultsRecordCount setStringValue:resultCount];
        [[searchResultsDescriptionWebView mainFrame] loadHTMLString:movie.synopsis baseURL:[NSURL URLWithString:@""]];
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
    if (movie.boxArt) {
        boxArt = movie.boxArt;
    }
    else {
        NSManagedObjectContext* managedObjectContext = [movie managedObjectContext];
        NSEntityDescription* boxArtEntity = [NSEntityDescription entityForName:@"BoxArt" inManagedObjectContext:managedObjectContext];
        boxArt = [[BoxArt alloc] initWithEntity:boxArtEntity insertIntoManagedObjectContext:managedObjectContext];
        movie.boxArt = boxArt;
    }
    
    CGImageRef image = CGImageSourceCreateImageAtIndex(imageSource, 0, (CFDictionaryRef)[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], kCGImageSourceCreateThumbnailFromImageAlways, nil]);
    
    boxArt.state = @"Loaded";
    boxArt.url = [[query URL] absoluteString];
    boxArt.image = image;
    
    CGImageRelease(image);
}


@end
