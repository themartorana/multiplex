#import "MovieLookupController.h"
#import "ApplicationController.h"
#import "DrawerView.h"
#import "Movie.h"
#import "Activity.h"
#import "ApplicationResources.h"
#import "CoverArtImageView.h"
#import "BoxArt.h"

#import "AmazonQuery.h"
#import "ImageQuery.h"

#import <DiscIdentKit/DiscIdentKit.h>
#import <WebKit/WebKit.h>
#import <Toolkit/Toolkit.h>

static NSString* const kAmazonAccessKey = @"01Y2NSCMDJ3VJXTCBTR2";

@interface MovieLookupController (Private)
- (void) showResultAtIndex:(int)index;
@end


@implementation MovieLookupController
@synthesize movie;

- (id) initWithApplicationController:(ApplicationController*)_applicationController drawerView:(DrawerView*)_drawerView
{
    NSAssert(_applicationController, @"wtf?");
    NSAssert(_drawerView, @"wtf?");
    if (self = [super init]) {
        applicationController = [_applicationController retain];
        drawerView = [_drawerView retain];
        if (![NSBundle loadNibNamed:@"MovieLookup" owner:self]) {
            return nil;
        }
    }
    return self;
}

- (void) awakeFromNib
{
    [searchResultsDescriptionWebView setDrawsBackground:NO];
    [searchResultsDescriptionWebView setPreferences:[ApplicationResources movieDescriptionWebPreferences]];
    [searchResultsBoxArt bind:@"image" toObject:self withKeyPath:@"movie.boxArt.image" options:[NSDictionary dictionaryWithObjectsAndKeys:(id)[ApplicationResources CGImageFromResource:@"drag-drop-no-image" ofType:@"pdf"], NSNullPlaceholderBindingOption, nil]];
}

- (void) setMovie:(Movie*)_movie
{
    if (movie != _movie) {
        [self willChangeValueForKey:@"movie"];
        [movie release];
        movie = [_movie retain];
        managedObjectContext = [movie managedObjectContext];
        boxArtEntity = [NSEntityDescription entityForName:@"BoxArt" inManagedObjectContext:managedObjectContext];
        [self didChangeValueForKey:@"movie"];
    }
}

- (void) startWithMovie:(Movie*)_movie
{
    resultIndex = 0;
    [titleTextField setStringValue:@""];
    [upcTextField setStringValue:@""];
    [self setMovie:_movie];
    [drawerView setContentView:searchForMovieView];
}

- (IBAction) cancel:(id)sender
{
    [[movie managedObjectContext] rollback];
    [applicationController showMovieDetailAndSelectHomeTabForMovie:movie];
}

- (IBAction) lookUpUPC:(id)sender
{
    NSMutableString* ean = [NSMutableString stringWithString:[upcTextField stringValue]];
    while ([ean length] < 13) {
        [ean insertString:@"0" atIndex:0];
    }
    amazonQuery = [[AmazonQuery amazonQueryWithAccessKey:kAmazonAccessKey ean:ean delegate:self userInfo:[Activity activityWithName:@"Looking up by UPC code" userInfo:nil] startImmediately:YES] retain];
    [drawerView setContentView:searchingView];
}

- (IBAction) lookUpTitle:(id)sender
{
    NSMutableString* title = [NSMutableString stringWithString:[titleTextField stringValue]];
    amazonQuery = [[AmazonQuery amazonQueryWithAccessKey:kAmazonAccessKey titleKeywords:title delegate:self userInfo:[Activity activityWithName:@"Looking up by title" userInfo:nil] startImmediately:YES] retain];
    [drawerView setContentView:searchingView];
}

- (IBAction) selectResult:(id)sender
{
    NSError* error = nil;
    [[movie managedObjectContext] save:&error];
    if (error) {
        NSLog(@"%@", [error userInfo]);
        NSAssert(FALSE, @"ERROR SAVING DATA!");
    }
    [applicationController showMovieDetailAndSelectHomeTabForMovie:nil];
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
    
    if ([resultAtIndex objectForKey:@"_coverImageURL"]) {
        NSString* urlAsString = [resultAtIndex objectForKey:@"_coverImageURL"];
        NSFetchRequest* fetchRequest = [[[NSFetchRequest alloc] init] autorelease];
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"url == %@", urlAsString];
        fetchRequest.entity = boxArtEntity;
        NSArray* results = [managedObjectContext executeFetchRequest:fetchRequest error:nil];
        BoxArt* boxArt = nil;
        if ([results count]) {
            boxArt = [results objectAtIndex:0];
        } else {
            boxArt = [[BoxArt alloc] initWithEntity:boxArtEntity insertIntoManagedObjectContext:managedObjectContext];
            boxArt.state = @"Loading";
            boxArt.url = urlAsString;
            imageQuery = [[ImageQuery imageQueryWithURL:[NSURL URLWithString:urlAsString] delegate:self userInfo:[Activity activityWithName:@"Loading Box Art" userInfo:boxArt.objectID] startImmediately:YES] retain];
        }
        movie.boxArt = boxArt;
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
        
        if (AmazonQueryTypeEAN == amazonQuery.queryType) {
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
        message = [NSString stringWithFormat:@"No results were found for the UPC code (%@).", upc];
    } else {
        message = @"No results were found.";
    }
    NSAlert* alert = [NSAlert alertWithMessageText:message defaultButton:@"Ok" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Please check your information and try again.."];
    [alert beginSheetModalForWindow:[upcTextField window] modalDelegate:nil didEndSelector:nil contextInfo:nil];    
}

#pragma mark "AmazonQuery delegate methods"

- (void) amazonQuery:(AmazonQuery*)query didFailWithError:(NSError*)error userInfo:(id)userInfo
{
    Activity* activity = userInfo;
    @try {
        NSLog(@"AMAZON QUERY ERROR: %@", error);
        [drawerView setContentView:searchForMovieView];
        [self showNoResultsSheet];
    } @finally {
        [activity terminate];
    }
}

- (void) amazonQuery:(AmazonQuery*)query didReceiveResponse:(NSArray*)response userInfo:(id)userInfo
{    
    Activity* activity = userInfo;
    @try {
        if (![response count]) {
            [self showNoResultsSheet];
        } else {
            if (amazonQueryResults) {
                [amazonQueryResults release];
                amazonQueryResults = nil;
            }
            amazonQueryResults = [response retain];
            resultIndex = 0;
            [self showResultAtIndex:0];
        }
    } @finally {
        [activity terminate];
    }
}

#pragma mark "ImageQuery delegate methods"

- (void) imageQuery:(ImageQuery*)quert didFailWithError:(NSError*)error userInfo:(id)userInfo
{
    Activity* activity = userInfo;
    @try {
        NSLog(@"IMAGE QUERY ERROR: %@", error);
        BoxArt* boxArt = (BoxArt*)[managedObjectContext objectWithID:activity.userInfo];
        boxArt.state = @"Error";
    } @finally {
        [activity terminate];
    }
}

- (void) imageQuery:(ImageQuery*)query didReceiveImageSource:(CGImageSourceRef)imageSource userInfo:(id)userInfo;
{
    Activity* activity = userInfo;
    @try {
        BoxArt* boxArt = (BoxArt*)[managedObjectContext objectWithID:activity.userInfo];
        CGImageRef image = CGImageSourceCreateImageAtIndex(imageSource, 0, (CFDictionaryRef)[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], kCGImageSourceCreateThumbnailFromImageAlways, nil]);
        boxArt.state = @"Loaded";
        boxArt.image = image;
        CGImageRelease(image);
    } @finally {
        [activity terminate];
    }
}

@end
