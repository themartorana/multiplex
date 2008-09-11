#import "EngineController.h"
#import "MessageProtocol.h"
#import "NSString+UUID.h"
#import <unistd.h>
#import <netinet/ip.h>
#import <netinet/ip6.h>

@interface EngineController (Private)
- (void) deleteAllMediaForThisEngine;
- (void) deleteAllMoviesWithNoMedia;
- (NSManagedObject*) findDiscByFingerprint:(NSString*)fingerprint;
- (NSManagedObject*) findMovieByGTIN:(NSString*)gtin;
- (NSManagedObject*) findMediaByURL:(NSString*)url;
- (void) deleteMovieIfNoMediaRemain:(NSManagedObject*)movie;
@end


@implementation EngineController

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
        if (a->sa_len == sizeof(struct sockaddr_in) && a->sa_family == AF_INET) {
            int s = socket(AF_INET, SOCK_STREAM, 0);
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
        } else if (a->sa_len == sizeof(struct sockaddr_in6) && a->sa_family == AF_INET6) {
            int s = socket(AF_INET6, SOCK_STREAM, 0);
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
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"engine == %@", machineId]];
    NSError* error = nil;
    NSArray* results = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    [fetchRequest release];
    if (!error && [results count]) {
        for (NSManagedObject* media in results) {
            [managedObjectContext deleteObject:media];
        }
    }
}

- (void) deleteAllMoviesWithNoMedia
{
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:discDesc];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"media.@count == 0"]];
    NSError* error = nil;
    NSArray* results = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    [fetchRequest release];
    NSCountedSet* set = [NSCountedSet set];
    if (!error && [results count]) {
        for (NSManagedObject* disc in results) {
            [set addObject:[disc valueForKey:@"movie"]];
        }
        for (NSManagedObject* movie in set) {
            if ([[movie valueForKey:@"discs"] count] == [set countForObject:movie]) {
                [managedObjectContext deleteObject:movie];
            }
        }
    }
}

- (NSManagedObject*) findDiscByFingerprint:(NSString*)fingerprint
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

- (NSManagedObject*) findMovieByGTIN:(NSString*)gtin
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

- (NSManagedObject*) findMediaByURL:(NSString*)url
{
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:mediaDesc];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"engine == %@ && url == %@", machineId, url]]; 
    NSError* error = nil;
    NSArray* results = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    [fetchRequest release];
    if (!error && [results count]) {
        return [results objectAtIndex:0];
    }
    return nil;
}

- (void) deleteMovieIfNoMediaRemain:(NSManagedObject*)movie  
{
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:discDesc];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"movie == %@ && media.@count == 0", movie]];
    NSError* error = nil;
    NSArray* results = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    [fetchRequest release];
    if (!error && [results count] == [[movie valueForKey:@"discs"] count]) {
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
            NSManagedObject* disc = [self findDiscByFingerprint:fingerprint];
            if (!disc) {
                disc = [[[NSManagedObject alloc] initWithEntity:discDesc insertIntoManagedObjectContext:managedObjectContext] autorelease];
                [disc setValue:fingerprint forKey:@"fingerprint"];
            }
            
            /*  For each URL provided, create a media object to represent it,
             *  and attached it to our disc.
             */
            for (NSString* url in [info objectForKey:@"urls"]) {
                NSManagedObject* media = [[NSManagedObject alloc] initWithEntity:mediaDesc insertIntoManagedObjectContext:managedObjectContext];
                [media setValue:url forKey:@"url"];
                [media setValue:machineId forKey:@"engine"];
                [media setValue:disc forKey:@"disc"];
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
            NSManagedObject* disc = [self findDiscByFingerprint:fingerprint];
            NSAssert(disc, @"no disc?");
            
            /*  Figure out which movie to attach this disc to.  We may have 
             *  created a temporary movie that could need to be deleted if 
             *  another already exists with a particular GTIN.
             */
            NSString* gtin = [movieInfo objectForKey:@"gtin"];
            NSManagedObject* movie = gtin ? [self findMovieByGTIN:gtin] : nil;
            if (movie) {
                NSManagedObject* oldMovie = [disc valueForKey:@"movie"];
                if ([movie isNotEqualTo:oldMovie]) {
                    [disc setValue:movie forKey:@"movie"];
                    if (oldMovie) {
                        [self deleteMovieIfNoMediaRemain:oldMovie];
                    }
                }
            } else {
                movie = [disc valueForKey:@"movie"];
                if (!movie) {
                    movie = [[[NSManagedObject alloc] initWithEntity:movieDesc insertIntoManagedObjectContext:managedObjectContext] autorelease];
                }
                if (gtin) {
                    [movie setValue:gtin forKey:@"gtin"];
                }
                [disc setValue:movie forKey:@"movie"];
            }
            
            /*  Set any movie-related properties.
             */
            NSString* aspect_ratio = [movieInfo objectForKey:@"aspect_ratio"];
            if (aspect_ratio) {
                [movie setValue:aspect_ratio forKey:@"aspectRatio"];
            }
            NSString* review = [movieInfo objectForKey:@"review"];
            if (review) {
                [movie setValue:review forKey:@"review"];
            }
            NSString* synopsis = [movieInfo objectForKey:@"synopsis"];
            if (synopsis) {
                [movie setValue:synopsis forKey:@"synopsis"];
            }
            NSString* title = [movieInfo objectForKey:@"title"];
            if (title) {
                [movie setValue:title forKey:@"title"];
            }
            
            /*  If there is a "discs" dictionary present, enumerate it's keys,
             *  creating disc objects and associating them with the movie that
             *  we're attaching ourselves to.
             */
            NSDictionary* discInfo = [movieInfo objectForKey:@"discs"];
            for (NSString* discInfoFingerprint in discInfo) {
                NSDictionary* otherDiscInfo = [discInfo objectForKey:discInfoFingerprint];
                NSManagedObject* disc = [self findDiscByFingerprint:discInfoFingerprint];
                if (!disc) {
                    disc = [[[NSManagedObject alloc] initWithEntity:discDesc insertIntoManagedObjectContext:managedObjectContext] autorelease];
                    [disc setValue:discInfoFingerprint forKey:@"fingerprint"];
                }
                NSString* tag = [otherDiscInfo objectForKey:@"tag"];
                if (tag && [tag length] == 2) {
                    int number = [tag characterAtIndex:0] - '0';
                    if (number >= 1 && number <= 9) {
                        [disc setValue:[NSNumber numberWithInt:number] forKey:@"number"];
                    }
                    [disc setValue:[tag substringFromIndex:1] forKey:@"side"];
                }
                NSManagedObject* movieForDisc = [disc valueForKey:@"movie"];
                if (movie != movieForDisc) {
                    [disc setValue:movie forKey:@"movie"];
                    if (movieForDisc) {
                        [self deleteMovieIfNoMediaRemain:movieForDisc];
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
                NSManagedObject* media = [self findMediaByURL:url];
                if (media) {
                    NSManagedObject* disc = [media valueForKey:@"disc"];
                    [managedObjectContext deleteObject:media];
                    int zeroCount = 0;
                    int total = 0;
                    NSManagedObject* movie = [disc valueForKey:@"movie"];
                    for (NSManagedObject* otherDisc in [movie valueForKey:@"discs"]) {
                        int count = [[otherDisc valueForKey:@"media"] count];
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