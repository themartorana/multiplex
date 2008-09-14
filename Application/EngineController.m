#import "EngineController.h"
#import "MessageProtocol.h"
#import "Media.h"
#import "Movie.h"
#import "Disc.h"
#import "Engine.h"
#import "NSString+UUID.h"

#import <unistd.h>
#import <netinet/ip.h>
#import <netinet/ip6.h>

@interface EngineController (Private)
- (BOOL) connectEngine:(Engine*)engine;
- (void) disconnectEngine:(Engine*)engine;
- (void) deleteAllMediaForEngine:(Engine*)engine;
- (void) deleteAllMoviesWithNoMedia;
- (Disc*) findDiscByFingerprint:(NSString*)fingerprint;
- (Movie*) findMovieByGTIN:(NSString*)gtin;
- (Media*) findMediaByEngine:(Engine*)engine URL:(NSString*)_url;
- (Engine*) findEngineByUUID:(NSString*)UUID;
- (void) deleteMovieIfNoMediaRemainForAnyDisc:(Movie*)movie;
@end

@interface EngineController (NSNetServiceDelegate)
- (void) netService:(NSNetService*)netService didNotResolve:(NSDictionary*)errorDict;
- (void) netServiceDidResolveAddress:(NSNetService*)netService;
@end

@interface EngineController (NSNetServiceBrowserDelegate)
- (void) netServiceBrowser:(NSNetServiceBrowser*)netServiceBrowser didFindService:(NSNetService*)netService moreComing:(BOOL)moreComing;
- (void) netServiceBrowser:(NSNetServiceBrowser*)netServiceBrowser didRemoveService:(NSNetService*)netService moreComing:(BOOL)moreComing; 
@end

#pragma mark -
@implementation EngineController

- (id) initWithManagedObjectContext:(NSManagedObjectContext*)_managedObjectContext 
{
    if (self = [super init]) {
        netServiceByName = [[NSMutableDictionary alloc] init];
        protocolsByUUID = [[NSMutableDictionary alloc] init];
        managedObjectContext = [_managedObjectContext retain];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_coreDataChangeNotification:) name:NSManagedObjectContextObjectsDidChangeNotification object:managedObjectContext];

        NSUserDefaults* engineDefaults = [[NSUserDefaults alloc] init];
        [engineDefaults addSuiteNamed:@"com.multiplexapp.Engine"];
        localMachineUUID = [engineDefaults valueForKey:@"machine-id"];
        if (!localMachineUUID) {
            [engineDefaults setValue:localMachineUUID = [NSString stringWithUUID] forKey:@"machine-id"];
            [engineDefaults synchronize];
        }
        [engineDefaults release];
        
        browser = [[NSNetServiceBrowser alloc] init];
        [browser setDelegate:self];
        [browser searchForServicesOfType:@"_com_multiplexapp_Engine._tcp." inDomain:@""]; 
        
        NSString* pathToEngine = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Engine"];
        NSTask* launchctl = [NSTask launchedTaskWithLaunchPath:@"/bin/launchctl" arguments:[NSArray arrayWithObjects:@"submit", @"-l", @"com.multiplexapp.Engine", pathToEngine, nil]];
        [launchctl waitUntilExit];
        if (0 == [launchctl terminationStatus]) {
            NSLog(@"Started local engine.");
        } else {
            NSLog(@"Local engine may already be running.");
        }
        
        engineDesc = [[NSEntityDescription entityForName:@"Engine" inManagedObjectContext:managedObjectContext] retain];
        mediaDesc = [[NSEntityDescription entityForName:@"Media" inManagedObjectContext:managedObjectContext] retain];
        discDesc = [[NSEntityDescription entityForName:@"Disc" inManagedObjectContext:managedObjectContext] retain];
        movieDesc = [[NSEntityDescription entityForName:@"Movie" inManagedObjectContext:managedObjectContext] retain];
    }
    
    return self;
}

- (void) dealloc
{
    NSAssert(0 == [protocolsByUUID count], @"stop not called before dealloc");
    [protocolsByUUID release];
    [netServiceByName release];
    /**/
    [browser release];
    [localMachineUUID release];
    [managedObjectContext release];
    /**/
    [engineDesc release];
    [mediaDesc release];
    [discDesc release];
    [movieDesc release];
    /**/
    [super dealloc];
}

- (void) stop 
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [browser stop];
    [browser removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    for (NSString* uuid in protocolsByUUID) {
        MessageProtocol* protocol = [protocolsByUUID objectForKey:uuid];
        [protocol close];
    }
    [protocolsByUUID removeAllObjects];
    
    NSTask* launchctl = [NSTask launchedTaskWithLaunchPath:@"/bin/launchctl" arguments:[NSArray arrayWithObjects:@"remove", @"com.multiplexapp.Engine", nil]];
    [launchctl waitUntilExit];
    if (0 == [launchctl terminationStatus]) {
        NSLog(@"Stoppped local engine.");
    } else {
        NSLog(@"Local engine may still be running.");
    }
}

- (void) _coreDataChangeNotification:(NSNotification*)notification
{
    if (pushingBackChanges) {
        for (NSManagedObject* managedObject in [[notification userInfo] objectForKey:NSUpdatedObjectsKey]) {
            NSString* entityName = [[managedObject entity] name];
            NSLog(@"%@", managedObject);
            NSLog(@"%@", [[managedObject changedValues] allKeys]);
            if ([@"Disc" isEqualToString:entityName]) {
            } else if ([@"Movie" isEqualToString:entityName]) {
                NSArray* keys = [[managedObject changedValues] allKeys];
                if ([keys count] == 1 && [[keys objectAtIndex:0] isEqualToString:@"movieDiscs"]) {
                    continue;
                }
            }
        }
    }
}

@end


#pragma mark -
@implementation EngineController (Private)

- (BOOL) connectEngine:(Engine*)engine
{
    NSAssert(engine, @"no engine?");
    if ([protocolsByUUID objectForKey:engine.uuid]) {
        return NO;
    }
    NSNetService* netService = [netServiceByName objectForKey:engine.netServiceName];
    NSAssert(netService, @"no net service?");

    engine.status = @"Connecting";
    MessageProtocol* protocol = nil;
    for (NSData* address in [netService addresses]) {
        const struct sockaddr* a = [address bytes];
        int s = socket(a->sa_family, SOCK_STREAM, 0);
        if (s >= 0) {
            if (0 == connect(s, a, a->sa_len)) {
                NSFileHandle* fileHandle = [[NSFileHandle alloc] initWithFileDescriptor:s closeOnDealloc:YES];
                protocol = [MessageProtocol protocolWithDelegate:self fileHandleForReading:fileHandle fileHandleForWriting:fileHandle];
                protocol.userInfo = [engine.uuid retain];
                [protocolsByUUID setObject:protocol forKey:engine.uuid];
                [fileHandle release];
                break;
            } else {
                close(s);
            }
        }
    }
    
    if (protocol) {
        engine.status = @"Connected";
        return YES;
    } else {
        engine.status = @"Not Connected";
        return NO;
    }
}

- (void) disconnectEngine:(Engine*)engine
{
    NSAssert(engine, @"no engine?");
    engine.status = @"Disconnecting";
    MessageProtocol* protocol = [protocolsByUUID objectForKey:engine.uuid];
    if (protocol) {
        NSString* uuid = protocol.userInfo;
        NSAssert([uuid isEqualToString:engine.uuid], @"Why don't these match?");
        @try {
            [protocol close];
        } @catch (NSException* ex) {
            /* Ignored */
        } @finally {
            [self deleteAllMediaForEngine:engine];
            [self deleteAllMoviesWithNoMedia];
            [protocolsByUUID removeObjectForKey:engine.uuid];
            engine.status = @"Not Connected";
        }
        [uuid release];
        [managedObjectContext save:nil];
    }
}

- (void) deleteAllMediaForEngine:(Engine*)engine
{
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:mediaDesc];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"engine == %@", engine]];
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

- (Media*) findMediaByEngine:(Engine*)engine URL:(NSString*)_url
{
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:mediaDesc];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"engine == %@ && url == %@", engine, _url]]; 
    NSError* error = nil;
    NSArray* results = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    [fetchRequest release];
    if (!error && [results count]) {
        return [results objectAtIndex:0];
    }
    return nil;
}

- (Engine*) findEngineByUUID:(NSString*)UUID
{
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:engineDesc];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"uuid == %@", UUID]]; 
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

- (void) protocolDidClose:(MessageProtocol*)protocol
{
    @try {
        NSString* uuid = protocol.userInfo;
        Engine* engine = [self findEngineByUUID:uuid];
        [self disconnectEngine:engine];
    } @catch (id exception) {
        /* ignored */
    } @finally {
        [managedObjectContext save:nil];
    }
}

- (void) protocol:(MessageProtocol*)protocol didReceiveMessage:(NSDictionary*)message 
{
    Engine* engine = [self findEngineByUUID:[protocol userInfo]];
    
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
                media.engine = engine;
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
                Media* media = [self findMediaByEngine:engine URL:url];
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


#pragma mark -
@implementation EngineController (NSNetServiceDelegate)

- (void) netService:(NSNetService*)netService didNotResolve:(NSDictionary*)errorDict
{
    NSLog(@"There was an error while attempting to resolve %@.", [netService name]);
}

- (void) netServiceDidResolveAddress:(NSNetService*)netService
{
    NSDictionary* rawData = [NSNetService dictionaryFromTXTRecordData:[netService TXTRecordData]];
    NSString* uuid = [[[NSString alloc] initWithData:[rawData objectForKey:@"UUID"] encoding:NSUTF8StringEncoding] autorelease];
    NSString* name = [[[NSString alloc] initWithData:[rawData objectForKey:@"Name"] encoding:NSUTF8StringEncoding] autorelease];
    if ([uuid length] && [name length]) {
        Engine* engine = [[Engine alloc] initWithEntity:engineDesc insertIntoManagedObjectContext:managedObjectContext];
        engine.uuid = uuid;
        engine.name = name;
        engine.netServiceName = [netService name];
        [managedObjectContext save:nil];
        if (YES || [uuid isEqualToString:localMachineUUID]) {
            [self connectEngine:engine];
        }
    }
}

@end


#pragma mark -
@implementation EngineController (NSNetServiceBrowserDelegate)

- (void) netServiceBrowser:(NSNetServiceBrowser*)netServiceBrowser didFindService:(NSNetService*)netService moreComing:(BOOL)moreComing
{
    [netServiceByName setObject:netService forKey:[netService name]];
    [netService setDelegate:self];
    [netService resolveWithTimeout:5.0];
}

- (void) netServiceBrowser:(NSNetServiceBrowser*)netServiceBrowser didRemoveService:(NSNetService*)netService moreComing:(BOOL)moreComing 
{
    [netService stop];
    [netServiceByName removeObjectForKey:[netService name]];
}

@end
