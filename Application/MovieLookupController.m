#import "MovieLookupController.h"
#import "ApplicationController.h"
#import "DrawerView.h"
#import "Movie.h"
#import "Activity.h"
#import "ApplicationResources.h"
#import "BoxArtImageView.h"
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
@synthesize amazonQueryResults;
@synthesize resultIndex;

+ (NSSet*) keyPathsForValuesAffectingValueForKey:(NSString*)keyPath
{
    if ([keyPath isEqualToString:@"resultViewLineOneText"] || [keyPath isEqualToString:@"resultViewLineTwoText"]) {
        return [NSSet setWithObject:@"amazonQueryResults"];
    } else {
        return [super keyPathsForValuesAffectingValueForKey:keyPath];
    }
}

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

- (NSString*) resultViewLineOneText
{
    return [amazonQueryResults count] == 1 ? @"Is This Your Movie?" : @"Which Is Your Movie?";
}

- (NSString*) resultViewLineTwoText
{
    return [amazonQueryResults count] == 1 ? @"Multiplex found one possible match." : [NSString stringWithFormat:@"Multiplex found %d possible matches...", [amazonQueryResults count]];
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

- (void) setResultIndex:(NSNumber*)_resultIndex
{
    if (resultIndex != _resultIndex) {
        [self willChangeValueForKey:@"resultIndex"];
        [resultIndex release];
        resultIndex = [_resultIndex retain];
        [self didChangeValueForKey:@"resultIndex"];

        if ([drawerView contentView] != searchResultsView) {
            [drawerView setContentView:searchResultsView];
        }
        
        BoxArt* boxArt = nil;
        NSDictionary* resultAtIndex = nil;
        int index = [resultIndex intValue] - 1;
        if (index < [amazonQueryResults count] && index >= 0) {
            resultAtIndex = [amazonQueryResults objectAtIndex:index];
        }
        
        if (resultAtIndex) {
            NSString* urlAsString = [resultAtIndex objectForKey:@"_coverImageURL"];
            if ([urlAsString length]) {
                NSFetchRequest* fetchRequest = [[[NSFetchRequest alloc] init] autorelease];
                fetchRequest.predicate = [NSPredicate predicateWithFormat:@"url == %@", urlAsString];
                fetchRequest.entity = boxArtEntity;
                NSArray* results = [managedObjectContext executeFetchRequest:fetchRequest error:nil];
                if ([results count]) {
                    boxArt = [results objectAtIndex:0];
                } else {
                    boxArt = [[BoxArt alloc] initWithEntity:boxArtEntity insertIntoManagedObjectContext:managedObjectContext];
                    boxArt.url = urlAsString;
                    boxArt.state = @"Loading";
                    [ImageQuery imageQueryWithURL:[NSURL URLWithString:urlAsString] delegate:self userInfo:[Activity activityWithName:@"Loading Box Art" userInfo:boxArt.objectID] startImmediately:YES];
                }
            }

            movie.title = [resultAtIndex objectForKey:@"title"];
            movie.aspectRatio = [resultAtIndex objectForKey:@"aspectRatio"];
            movie.genre = [resultAtIndex objectForKey:@"genre"];
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
            
            if (AmazonQueryTypeEAN == amazonQueryType) {
                NSMutableString* gtin = [NSMutableString stringWithString:[eanTextField stringValue]];
                while ([gtin length] < 14) {
                    [gtin insertString:@"0" atIndex:0];
                }
                movie.gtin = gtin;
            }
            
            NSMutableString* addOnString = [NSMutableString string];
            [addOnString appendFormat:@"<div id=\"multiplex_results_count\">Result %d of %d</div>", [_resultIndex intValue], [amazonQueryResults count]];
            [addOnString appendFormat:@"<div id=\"multiplex_results_title\">%@</div>", movie.title];
            [addOnString appendString:movie.synopsis];
            
            [[searchResultsDescriptionWebView mainFrame] loadHTMLString:addOnString baseURL:[NSURL URLWithString:@""]];
        }

        movie.boxArt = boxArt;
    }
}

- (void) startWithMovie:(Movie*)_movie
{
    if (movie) {
        [managedObjectContext rollback];
        [managedObjectContext refreshObject:movie mergeChanges:YES];
    }
    
    [self setResultIndex:nil];
    [self setAmazonQueryResults:nil];
    [self setMovie:_movie];
    
    NSString* gtin = movie.gtin;
    if (gtin) {
        if ([gtin length] == 14 && [gtin characterAtIndex:0] == '0') {
            gtin = [gtin substringFromIndex:1];
        }        
    } else {
        gtin = @"";
    }
    [eanTextField setStringValue:gtin];

    NSString* title = movie.title;
    if (title) {
        int indexOfParen = [title rangeOfString:@"("].location;
        if (indexOfParen != NSNotFound) {
            title = [title substringToIndex:indexOfParen];
        }
        int indexOfDash = [title rangeOfString:@"-"].location;
        if (indexOfDash != NSNotFound) {
            title = [title substringToIndex:indexOfDash];
        }
    } else {
        title = @"";
    }
    [titleTextField setStringValue:title];

    [drawerView setContentView:searchByUPCorEANView];
}

- (IBAction) skipToTitleEntry:(id)sender
{
    [drawerView setContentView:searchByTitleView];
}


- (IBAction) skipToManualEntry:(id)sender
{
    [[movie managedObjectContext] rollback];
    [managedObjectContext refreshObject:movie mergeChanges:NO];
    [applicationController showMovieDetailAndSelectHomeTabForMovie:movie];
}

- (IBAction) lookUpByUPCorEAN:(id)sender
{
    NSMutableString* ean = [NSMutableString stringWithString:[eanTextField stringValue]];
    while ([ean length] < 13) {
        [ean insertString:@"0" atIndex:0];
    }
    if ([ean length] > 13) {
        // TODO: Handle Me Gracefully.
    }
    [self setAmazonQueryResults:nil];
    [self setResultIndex:nil];
    [AmazonQuery amazonQueryWithAccessKey:kAmazonAccessKey ean:ean delegate:self userInfo:[Activity activityWithName:@"Looking up by UPC code" userInfo:nil] startImmediately:YES];
    [drawerView setContentView:searchingView];
}

- (IBAction) lookUpByTitle:(id)sender
{
    [self setAmazonQueryResults:nil];
    [self setResultIndex:nil];
    [AmazonQuery amazonQueryWithAccessKey:kAmazonAccessKey titleKeywords:[titleTextField stringValue] delegate:self userInfo:[Activity activityWithName:@"Looking up by title" userInfo:nil] startImmediately:YES];
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
    [applicationController showMovieDetailAndSelectHomeTabForMovie:movie];
}

- (IBAction) showNextResult:(id)sender
{
    int value = [resultIndex intValue] + 1;
    if (value > [amazonQueryResults count]) {
        value = 1;
    }
    [self setResultIndex:[NSNumber numberWithInt:value]];
}

- (IBAction) showPreviousResult:(id)sender
{
    int value = [resultIndex intValue] - 1;
    if (value < 1) {
        value = [amazonQueryResults count];
    } 
    [self setResultIndex:[NSNumber numberWithInt:value]];
}

- (IBAction) backToSearch:(id)sender
{
    [[movie managedObjectContext] rollback];
    [managedObjectContext refreshObject:movie mergeChanges:NO];
    [drawerView setContentView:searchByUPCorEANView];
}

- (void) showNoResultsSheet
{
    NSString* upc = [eanTextField stringValue];
    NSString* message = nil;
    
    if (upc && [upc length]) {
        message = [NSString stringWithFormat:@"No results were found for the UPC code (%@).", upc];
    } else {
        message = @"No results were found.";
    }
    NSAlert* alert = [NSAlert alertWithMessageText:message defaultButton:@"Ok" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Please check your information and try again.."];
    [alert beginSheetModalForWindow:[eanTextField window] modalDelegate:nil didEndSelector:nil contextInfo:nil];    
}

#pragma mark "AmazonQuery delegate methods"

- (void) amazonQuery:(AmazonQuery*)query didFailWithError:(NSError*)error userInfo:(id)userInfo
{
    Activity* activity = userInfo;
    @try {
        NSLog(@"AMAZON QUERY ERROR: %@", error);
        if (query.queryType == AmazonQueryTypeEAN) {
            [drawerView setContentView:searchByUPCorEANView];
        } else if (query.queryType == AmazonQueryTypeTitle) {
            [drawerView setContentView:searchByTitleView];
        }
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
            amazonQueryType = query.queryType;
            [self setAmazonQueryResults:response];
            [self setResultIndex:[NSNumber numberWithInt:1]];
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
