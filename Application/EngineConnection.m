#import "EngineConnection.h"
#import "MessageProtocol.h"
#import "NSString+UUID.h"
#import "Disc.h"
#import "Media.h"
#import "Movie.h"
#import <unistd.h>
#import <netinet/ip.h>
#import <netinet/ip6.h>

@interface EngineConnection (Private)
- (void) deleteAllMediaForThisEngine;
- (void) deleteAllMoviesWithNoMedia;
- (Disc*) findDiscByFingerprint:(NSString*)fingerprint;
- (Movie*) findMovieByGTIN:(NSString*)gtin;
- (Media*) findMediaByURL:(NSString*)url;
- (void) deleteMovieIfNoMediaRemainForAnyDisc:(Movie*)movie;
@end


@implementation EngineConnection

@synthesize machineName;
@synthesize machineId;

- (id) initWithNetService:(NSNetService*)_netService managedObjectContext:(NSManagedObjectContext*)_managedObjectContext options:(NSDictionary*)_options
{
    NSAssert(_netService, @"no net service?");
    NSAssert(_managedObjectContext, @"no managed object context?");
    NSAssert(_options, @"no options?");
    if (self = [super init]) {
        machineId = [[_options objectForKey:@"Machine ID"] retain];
        machineName = [[_options objectForKey:@"Machine Name"] retain];
        netService = [_netService retain];
        managedObjectContext = [_managedObjectContext retain];
                
        mediaDesc = [[NSEntityDescription entityForName:@"Media" inManagedObjectContext:managedObjectContext] retain];
        discDesc = [[NSEntityDescription entityForName:@"Disc" inManagedObjectContext:managedObjectContext] retain];
        movieDesc = [[NSEntityDescription entityForName:@"Movie" inManagedObjectContext:managedObjectContext] retain];
    }
    return self;
} 

- (void) dealloc
{
    NSAssert(!protocol, @"stop not called before dealloc!");
    [machineId release];
    [machineName release];
    [netService release];
    [managedObjectContext release];
    [mediaDesc release];
    [discDesc release];
    [movieDesc release];
    [super dealloc];
}

- (void) sendMessage:(NSDictionary*)message 
{
    [protocol sendMessage:message];
}

- (BOOL) connect
{
    NSAssert(!protocol, @"connection already active!");
    for (NSData* address in [netService addresses]) {
        const struct sockaddr* a = [address bytes];
        int s = socket(a->sa_family, SOCK_STREAM, 0);
        if (s >= 0) {
            if (0 == connect(s, a, a->sa_len)) {
                NSFileHandle* fileHandle = [[NSFileHandle alloc] initWithFileDescriptor:s closeOnDealloc:YES];
                protocol = [[MessageProtocol protocolWithDelegate:self fileHandleForReading:fileHandle fileHandleForWriting:fileHandle] retain];
                [fileHandle release];
                break;
            } else {
                close(s);
            }
        }
    }
    return protocol != nil;
}

- (void) disconnect 
{
    @try {
        [protocol close];
    } @catch (NSException* ex) {
        /* Ignored */
    } @finally {
        [self deleteAllMediaForThisEngine];
        [self deleteAllMoviesWithNoMedia];
        [managedObjectContext save:nil];
        [protocol release];
        protocol = nil;
    }
}

- (void) deleteAllMediaForThisEngine
{
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:mediaDesc];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"machineId == %@", machineId]];
    NSError* error = nil;
    NSArray* results = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    [fetchRequest release];
    if (!error && [results count]) {
        for (Media* media in results) {
            [managedObjectContext deleteObject:media];
        }
    }
}

- (void) deleteAllMoviesWithNoMedia
{
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:discDesc];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"allMedia.@count == 0"]];
    NSError* error = nil;
    NSArray* results = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    [fetchRequest release];
    NSCountedSet* set = [NSCountedSet set];
    if (!error && [results count]) {
        for (Disc* disc in results) {
            [set addObject:disc.movie];
        }
        for (Movie* movie in set) {
            if ([movie.allDiscs count] == [set countForObject:movie]) {
                [managedObjectContext deleteObject:movie];
            }
        }
    }
}

- (Disc*) findDiscByFingerprint:(NSString*)fingerprint
{
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:discDesc];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"fingerprint == %@", fingerprint]];
    NSError* error = nil;
    NSArray* results = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    [fetchRequest release];
    if (!error && [results count]) {
        return [results objectAtIndex:0];
    }
    return nil;
}

- (Movie*) findMovieByGTIN:(NSString*)gtin
{
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:movieDesc];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"gtin == %@", gtin]]; 
    NSError* error = nil;
    NSArray* results = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    [fetchRequest release];
    if (!error && [results count]) {
        return [results objectAtIndex:0];
    }
    return nil;
}

- (Media*) findMediaByURL:(NSString*)url
{
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:mediaDesc];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"machineId == %@ && url == %@", machineId, url]]; 
    NSError* error = nil;
    NSArray* results = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    [fetchRequest release];
    if (!error && [results count]) {
        return [results objectAtIndex:0];
    }
    return nil;
}

- (void) deleteMovieIfNoMediaRemainForAnyDisc:(Movie*)movie  
{
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:discDesc];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"movie == %@ && allMedia.@count == 0", movie]];
    NSError* error = nil;
    NSArray* results = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    [fetchRequest release];
    if (!error && [results count] == [movie.allDiscs count]) {
        [managedObjectContext deleteObject:movie];
    }
}

#pragma mark LibraryComProtocol delegate methods

- (void) protocol:(MessageProtocol*)protocol didReceiveMessage:(NSDictionary*)message 
{
    /*  Add
     */
    NSDictionary* add = [message objectForKey:@"add"];
    if (add && [add isKindOfClass:[NSDictionary class]]) {
        for (NSString* fingerprint in add) {
            NSDictionary* info = [add objectForKey:fingerprint];
            
            /*  Find or create the disc that's represented by our fingerprint.
             */
            Disc* disc = [self findDiscByFingerprint:fingerprint];
            if (!disc) {
                disc = [[[Disc alloc] initWithEntity:discDesc insertIntoManagedObjectContext:managedObjectContext] autorelease];
                disc.fingerprint = fingerprint;
            }
            
            /*  For each URL provided, create a media object to represent it,
             *  and attached it to our disc.
             */
            for (NSString* url in [info objectForKey:@"urls"]) {
                Media* media = [[Media alloc] initWithEntity:mediaDesc insertIntoManagedObjectContext:managedObjectContext];
                media.url = url;
                media.machineId = machineId;
                media.disc = disc;
                [media release];
            }
        }
    }
            
    /*  Update
     */
    NSDictionary* update = [message objectForKey:@"update"];
    if (update && [update isKindOfClass:[NSDictionary class]]) {
        for (NSString* fingerprint in update) {
            NSDictionary* info = [update objectForKey:fingerprint];
            NSDictionary* movieInfo = [info objectForKey:@"movie"];

            /*  Find the disc that's represented by our fingerprint.
             */
            Disc* disc = [self findDiscByFingerprint:fingerprint];
            NSAssert(disc, @"no disc?");
            
            /*  Figure out which movie to attach this disc to.  We may have 
             *  created a temporary movie that could need to be deleted if 
             *  another already exists with a particular GTIN.
             */
            NSString* gtin = [movieInfo objectForKey:@"gtin"];
            Movie* movie = gtin ? [self findMovieByGTIN:gtin] : nil;
            if (movie) {
                Movie* oldMovie = disc.movie;
                if ([movie isNotEqualTo:oldMovie]) {
                    disc.movie = movie;
                    if (oldMovie) {
                        [self deleteMovieIfNoMediaRemainForAnyDisc:oldMovie];
                    }
                }
            } else {
                movie = disc.movie;
                if (!movie) {
                    movie = [[[Movie alloc] initWithEntity:movieDesc insertIntoManagedObjectContext:managedObjectContext] autorelease];
                }
                if (gtin) {
                    movie.gtin = gtin;
                }
                disc.movie = movie;
            }
            
            /*  Set any movie-related properties.
             */
            NSString* aspectRatio = [movieInfo objectForKey:@"aspect_ratio"];
            if (aspectRatio) {
                movie.aspectRatio = aspectRatio;
            }
            NSString* review = [movieInfo objectForKey:@"review"];
            if (review) {
                movie.review = review;
            }
            NSString* synopsis = [movieInfo objectForKey:@"synopsis"];
            if (synopsis) {
                movie.synopsis = synopsis;
            }
            NSString* title = [movieInfo objectForKey:@"title"];
            if (title) {
                movie.title = title;
            }
            
            /*  If there is a "discs" dictionary present, enumerate it's keys,
             *  creating disc objects and associating them with the movie that
             *  we're attaching ourselves to.
             */
            NSDictionary* discInfo = [movieInfo objectForKey:@"discs"];
            for (NSString* discInfoFingerprint in discInfo) {
                NSDictionary* otherDiscInfo = [discInfo objectForKey:discInfoFingerprint];
                Disc* disc = [self findDiscByFingerprint:discInfoFingerprint];
                if (!disc) {
                    disc = [[[Disc alloc] initWithEntity:discDesc insertIntoManagedObjectContext:managedObjectContext] autorelease];
                    disc.fingerprint = discInfoFingerprint;
                }
                NSString* tag = [otherDiscInfo objectForKey:@"tag"];
                if (tag && [tag length] == 2) {
                    int number = [tag characterAtIndex:0] - '0';
                    if (number >= 1 && number <= 9) {
                        disc.number = [NSNumber numberWithInt:number];
                    }
                    disc.side = [tag substringFromIndex:1];
                }
                Movie* movieForDisc = disc.movie;
                if (movie != movieForDisc) {
                    disc.movie = movie;
                    if (movieForDisc) {
                        [self deleteMovieIfNoMediaRemainForAnyDisc:movieForDisc];
                    }
                }
            }
        }
    }
    
    /*  Delete
     */
    NSDictionary* delete = [message objectForKey:@"delete"];
    if (delete && [delete isKindOfClass:[NSDictionary class]]) {
        for (NSString* fingerprint in delete) {
            NSDictionary* info = [delete objectForKey:fingerprint];
            for (NSString* url in [info objectForKey:@"urls"]) {
                Media* media = [self findMediaByURL:url];
                if (media) {
                    Disc* disc = media.disc;
                    [managedObjectContext deleteObject:media];
                    int zeroCount = 0;
                    int total = 0;
                    Movie* movie = disc.movie;
                    for (Disc* otherDisc in movie.allDiscs) {
                        int count = [otherDisc.allMedia count];
                        zeroCount += (disc == otherDisc && (count == 1)) || (count == 0);
                        total++;
                    }
                    if (zeroCount == total) {
                        [managedObjectContext deleteObject:movie];
                    }
                }
            }
        }
    }

    /*  Persist out our changes.
     */
    [managedObjectContext save:nil];
}

@end