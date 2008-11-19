#import "MovieLookupController.h"
#import "ApplicationController.h"
#import "DrawerView.h"
#import "Movie.h"
#import "Participant.h"
#import "Activity.h"
#import "ApplicationResources.h"
#import "BoxArtImageView.h"
#import "BoxArt.h"
#import "MovieURL.h"

#import "AmazonQuery.h"
#import "ImageQuery.h"

#import <DiscIdentKit/DiscIdentKit.h>
#import <WebKit/WebKit.h>
#import <Toolkit/Toolkit.h>
#import <JSONKit/JSONKit.h>

static NSString* const kAmazonAccessKey = @"01Y2NSCMDJ3VJXTCBTR2";

@interface MovieLookupController (Private)
- (void) showResultAtIndex:(int)index;
- (void) clearNotificationListener;
- (void) removeManagedObjectContextObserver;
- (void) saveManagedObjectContext;
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

- (void) takeControl
{
}

- (BOOL) relinquishControl
{
    if ([managedObjectContext hasChanges]) {
        
        NSString* dirtyInfo = @"You have not selected a result as your movie.";
        NSMutableString* dirtyExplain = [NSMutableString string];
        [dirtyExplain appendString:@"To discard the search results and continue, click \"Ok\"\n\n"];
        [dirtyExplain appendString:@"To go back to the results screen, click \"Cancel\""];

        
        NSAlert* alert = [NSAlert alertWithMessageText:dirtyInfo
                                         defaultButton:@"Ok"
                                       alternateButton:@"Cancel"
                                           otherButton:nil
                             informativeTextWithFormat:dirtyExplain];
        
        int buttonClicked = [alert runModal];
        
        switch (buttonClicked) {
            case NSAlertDefaultReturn:
                [self backToSearch:nil];
                return YES;
                break;
            
            case NSAlertAlternateReturn:
            default:
                return NO;
                break;
        }
    }
    else {
        return YES;
    }
}

- (void) awakeFromNib
{
    [searchResultsDescriptionWebView setDrawsBackground:NO];
    [searchResultsDescriptionWebView setPreferences:[ApplicationResources movieDescriptionWebPreferences]];
    [searchResultsBoxArt bind:@"image" toObject:self withKeyPath:@"movie.boxArt.image" options:[NSDictionary dictionaryWithObjectsAndKeys:(id)[ApplicationResources CGImageFromResource:@"drag-drop-no-image" ofType:@"pdf"], NSNullPlaceholderBindingOption, nil]];
    
    [resultsBox setCornerRadius:5.0];
    [resultsBox setFillColor:[NSColor colorWithCalibratedWhite:1.0 alpha:0.1]];
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
    NSLog(@"is dirty: %d, is fault: %d", [[_movie managedObjectContext] hasChanges], [_movie isFault]);
    
    if (movie != _movie) {
        [self willChangeValueForKey:@"movie"];
        [movie release];
        movie = nil;
        movie = [_movie retain];
        managedObjectContext = [movie managedObjectContext];
        boxArtEntity = [NSEntityDescription entityForName:@"BoxArt" inManagedObjectContext:managedObjectContext];
        participantEntity = [NSEntityDescription entityForName:@"Participant" inManagedObjectContext:managedObjectContext];
        movieURLEntity = [NSEntityDescription entityForName:@"MovieURL" inManagedObjectContext:managedObjectContext];
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
            if (movie.genre) {
                NSArray* arr = [movie.genre componentsSeparatedByString:@","];
                for (NSString* str in arr) {
                    str = [str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                }
                
                movie.genre = [NSString stringWithObjectAsJSON:arr];
            }
            
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
            
            // Add in the actors
            for (Participant* p in movie.allParticipants) {
                [managedObjectContext deleteObject:p];
            }
            NSArray* actors = [resultAtIndex objectForKey:@"actors"];
            if (actors) {
                for (NSString* name in actors) {
                    Participant* p = [[Participant alloc] initWithEntity:participantEntity insertIntoManagedObjectContext:managedObjectContext];
                    p.name = name;
                    p.type = @"actor";
                    p.movie = movie;
                }
            }
            NSArray* directors = [resultAtIndex objectForKey:@"directors"];
            if (directors) {
                for (NSString* name in directors) {
                    Participant* p = [[Participant alloc] initWithEntity:participantEntity insertIntoManagedObjectContext:managedObjectContext];
                    p.name = name;
                    p.type = @"director";
                    p.position  = @"Director";
                    p.movie = movie;
                }
            }
            NSArray* creators = [resultAtIndex objectForKey:@"creators"];
            if (creators) {
                for (NSArray* creator in creators) {
                    Participant* p = [[Participant alloc] initWithEntity:participantEntity insertIntoManagedObjectContext:managedObjectContext];
                    p.name = [creator objectAtIndex:0];
                    p.type = @"creator";
                    
                    if ([creator count] > 1) {
                        p.position = [creator objectAtIndex:1];                        
                    }

                    p.movie = movie;
                }
            }
            
            // Add in the URL
            for (MovieURL* url in movie.allMovieURLs) {
                [managedObjectContext deleteObject:url];
            }
            NSString* amazonURL = [resultAtIndex objectForKey:@"_detailPageURL"];
            if (amazonURL) {
                MovieURL* url = [[MovieURL alloc] initWithEntity:movieURLEntity insertIntoManagedObjectContext:managedObjectContext];
                url.url = amazonURL;
                url.siteName = @"Amazon";
                url.movie = movie;
            }
            
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
            if (movie.synopsis) {
                [addOnString appendString:movie.synopsis];
            }
            
            [[searchResultsDescriptionWebView mainFrame] loadHTMLString:addOnString baseURL:[NSURL URLWithString:@""]];
        }

        if (boxArt != movie.boxArt) {
            movie.boxArt = boxArt;
        }
    }
}

- (void) startWithMovie:(Movie*)_movie
{
    [self setMovie:_movie];
    [self setResultIndex:nil];
    [self setAmazonQueryResults:nil];
     
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

- (IBAction) skipToUPCEntry:(id)sender
{
    [drawerView setContentView:searchByUPCorEANView];
}

- (IBAction) skipToTitleEntry:(id)sender
{
    [drawerView setContentView:searchByTitleView];
}

- (IBAction) skipToManualEntry:(id)sender
{
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
    movie.metadataAcceptedDate = [NSDate date];
    [self saveManagedObjectContext];
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
    [managedObjectContext rollback];
    [managedObjectContext processPendingChanges];
    [drawerView setContentView:searchByUPCorEANView];
}

- (void) saveManagedObjectContext
{
    NSError* error = nil;
    [managedObjectContext save:&error];
    
    if (error) {
        NSLog(@"%@", [error userInfo]);
    }
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
        //CGImageRelease(image);
    } @finally {
        [activity terminate];
    }
}

@end
