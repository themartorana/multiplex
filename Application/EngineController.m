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
- (void) _deleteAllMediaForEngine:(Engine*)engine;
- (void) _deleteAllMoviesWithNoMedia;
- (Disc*) _findDiscByFingerprint:(NSString*)fingerprint;
- (Movie*) _findMovieByGTIN:(NSString*)gtin;
- (Media*) _findMediaByEngine:(Engine*)engine URL:(NSString*)url;
- (Engine*) _findEngineByUUID:(NSString*)UUID;
- (Engine*) _findEngineByNetServiceName:(NSString*)netServiceName;
- (void) _deleteMovieIfNoMediaRemainForAnyDisc:(Movie*)movie;
@end

@interface EngineController (CoreData)
- (void) _coreDataDidSaveNotification:(NSNotification*)notification;
@end

@interface EngineController (MessageProtocolDelegate)
- (void) protocolDidClose:(MessageProtocol*)protocol;
- (void) protocol:(MessageProtocol*)protocol didReceiveMessage:(NSDictionary*)message;
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
        dateFormatter = [[NSDateFormatter alloc] initWithDateFormat:@"%Y-%m-%d" allowNaturalLanguage:NO];

        /*  Grab references to some commonly used entity descriptions.
         */
        engineDesc = [[NSEntityDescription entityForName:@"Engine" inManagedObjectContext:managedObjectContext] retain];
        mediaDesc = [[NSEntityDescription entityForName:@"Media" inManagedObjectContext:managedObjectContext] retain];
        discDesc = [[NSEntityDescription entityForName:@"Disc" inManagedObjectContext:managedObjectContext] retain];
        movieDesc = [[NSEntityDescription entityForName:@"Movie" inManagedObjectContext:managedObjectContext] retain];

        /*  Grab (or generate) our local machine's Engine UUID.
         */
        static CFStringRef const kEngineMachineIdKey = CFSTR("machine-id");
        static CFStringRef const kEngineAppDomain = CFSTR("com.multiplexapp.Engine");
        localMachineUUID = (NSString*)CFPreferencesCopyValue(kEngineMachineIdKey, kEngineAppDomain, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
        if (!localMachineUUID) {
            localMachineUUID = [[NSString stringWithUUID] retain];
            CFPreferencesSetValue(kEngineMachineIdKey, (CFStringRef)localMachineUUID, kEngineAppDomain, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
            CFPreferencesSynchronize(kEngineAppDomain, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
        }
        
        /*  Fire up the Bonjour service browser.
         */
        browser = [[NSNetServiceBrowser alloc] init];
        [browser setDelegate:self];
        [browser searchForServicesOfType:@"_com_multiplexapp_Engine._tcp." inDomain:@""]; 
        
        /*  Use launchctl to start the local engine (if one's not started 
         *  already.)
         */
        NSString* pathToEngine = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Engine"];
        NSTask* launchctl = [NSTask launchedTaskWithLaunchPath:@"/bin/launchctl" arguments:[NSArray arrayWithObjects:@"submit", @"-l", @"com.multiplexapp.Engine", pathToEngine, nil]];
        [launchctl waitUntilExit];
        if (0 == [launchctl terminationStatus]) {
            NSLog(@"Started local engine.");
        } else {
            NSLog(@"Local engine may already be running.");
        }
    }
    
    return self;
}

- (void) dealloc
{
    NSAssert(0 == [protocolsByUUID count], @"shutdown not called before dealloc");
    [protocolsByUUID release];
    [netServiceByName release];
    /**/
    [dateFormatter release];
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

- (void) shutdown 
{
    /*  Kill all notification-handlers.
     */
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    /*  Stop the Bonjour service browser.
     */
    [browser stop];
    [browser removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    /*  Close and clear all of our connections.
     */
    for (NSString* uuid in [NSDictionary dictionaryWithDictionary:protocolsByUUID]) {
        MessageProtocol* protocol = [protocolsByUUID objectForKey:uuid];
        [protocol close];
    }
    
    /*  Use launchctl to shutdown our local engine.
     */
    NSTask* launchctl = [NSTask launchedTaskWithLaunchPath:@"/bin/launchctl" arguments:[NSArray arrayWithObjects:@"remove", @"com.multiplexapp.Engine", nil]];
    [launchctl waitUntilExit];
    if (0 == [launchctl terminationStatus]) {
        NSLog(@"Stoppped local engine.");
    } else {
        NSLog(@"Local engine may still be running.");
    }
}

- (BOOL) connectEngine:(Engine*)engine
{
    NSAssert(engine, @"no engine?");
    if ([protocolsByUUID objectForKey:engine.uuid]) {
        return NO;
    }
    NSNetService* netService = [netServiceByName objectForKey:engine.netServiceName];
    NSAssert(netService, @"no net service?");
    
    engine.status = @"Connecting";
    [managedObjectContext save:nil];
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
    } else {
        engine.status = @"Not Connected";
    }
    [managedObjectContext save:nil];
    return protocol != nil;
}

- (void) disconnectEngine:(Engine*)engine
{
    NSAssert(engine, @"no engine?");
    engine.status = @"Disconnecting";
    [managedObjectContext save:nil];
    MessageProtocol* protocol = [protocolsByUUID objectForKey:engine.uuid];
    if (protocol) {
        NSString* uuid = protocol.userInfo;
        NSAssert([uuid isEqualToString:engine.uuid], @"Why don't these match?");
        @try {
            [protocol close];
        } @catch (NSException* ex) {
            /* Ignored */
        } @finally {
            [self _deleteAllMediaForEngine:engine];
            [self _deleteAllMoviesWithNoMedia];
            [protocolsByUUID removeObjectForKey:engine.uuid];
            engine.status = @"Not Connected";
        }
        [uuid release];
        [managedObjectContext save:nil];
    }
}

@end


#pragma mark -
@implementation EngineController (Private)

- (void) _deleteAllMediaForEngine:(Engine*)engine
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

- (void) _deleteAllMoviesWithNoMedia
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

- (Disc*) _findDiscByFingerprint:(NSString*)fingerprint
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

- (Movie*) _findMovieByGTIN:(NSString*)gtin
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

- (Media*) _findMediaByEngine:(Engine*)engine URL:(NSString*)url
{
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:mediaDesc];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"engine == %@ && url == %@", engine, url]]; 
    NSError* error = nil;
    NSArray* results = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    [fetchRequest release];
    if (!error && [results count]) {
        return [results objectAtIndex:0];
    }
    return nil;
}

- (Engine*) _findEngineByUUID:(NSString*)UUID
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

- (Engine*) _findEngineByNetServiceName:(NSString*)netServiceName
{
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:engineDesc];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"netServiceName == %@", netServiceName]]; 
    NSError* error = nil;
    NSArray* results = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    [fetchRequest release];
    if (!error && [results count]) {
        return [results objectAtIndex:0];
    }
    return nil;
}

- (void) _deleteMovieIfNoMediaRemainForAnyDisc:(Movie*)movie  
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

@end


#pragma mark -
@implementation EngineController (CoreData)

- (void) _coreDataDidSaveNotification:(NSNotification*)notification
{
    for (NSManagedObject* managedObject in [[notification userInfo] objectForKey:NSUpdatedObjectsKey]) {
        NSEntityDescription* const entityDescription = [managedObject entity];
        if (entityDescription == movieDesc) {
            NSLog(@"%@", managedObject);
            NSLog(@"%@", [[managedObject changedValues] allKeys]);
        } else if (entityDescription == discDesc) {
            NSLog(@"%@", managedObject);
            NSLog(@"%@", [[managedObject changedValues] allKeys]);
        }
    }
}

@end


#pragma mark -
@implementation EngineController (MessageProtocolDelegate)

- (void) protocolDidClose:(MessageProtocol*)protocol
{
    @try {
        NSString* uuid = protocol.userInfo;
        Engine* engine = [self _findEngineByUUID:uuid];
        [self disconnectEngine:engine];
    } @catch (id exception) {
        /* ignored */
    } @finally {
        [managedObjectContext save:nil];
    }
}

- (void) protocol:(MessageProtocol*)protocol didReceiveMessage:(NSDictionary*)message 
{
    Engine* engine = [self _findEngineByUUID:[protocol userInfo]];
    if (!engine) {
        return;
    }
    
    /*  Add
     */
    NSDictionary* add = [message objectForKey:@"add"];
    if (add && [add isKindOfClass:[NSDictionary class]]) {
        for (NSString* fingerprint in add) {
            NSDictionary* info = [add objectForKey:fingerprint];
            
            /*  Find or create the disc that's represented by our fingerprint.
             */
            Disc* disc = [self _findDiscByFingerprint:fingerprint];
            if (!disc) {
                disc = [[[Disc alloc] initWithEntity:discDesc insertIntoManagedObjectContext:managedObjectContext] autorelease];
                disc.fingerprint = fingerprint;
            }
            
            NSString* frontCoverURL = [info objectForKey:@"frontCoverURL"];
            
            /*  For each URL provided, create a media object to represent it,
             *  and attached it to our disc.
             */
            for (NSString* url in [info objectForKey:@"urls"]) {
                Media* media = [[Media alloc] initWithEntity:mediaDesc insertIntoManagedObjectContext:managedObjectContext];
                media.url = url;
                media.engine = engine;
                media.disc = disc;
                if (frontCoverURL) {
                    media.frontCoverURL = frontCoverURL;
                }
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
            Disc* disc = [self _findDiscByFingerprint:fingerprint];
            NSAssert(disc, @"no disc?");
            
            /*  Figure out which movie to attach this disc to.  We may have 
             *  created a temporary movie that could need to be deleted if 
             *  another already exists with a particular GTIN.
             */
            NSString* gtin = [movieInfo objectForKey:@"gtin"];
            Movie* movie = gtin ? [self _findMovieByGTIN:gtin] : nil;
            if (movie) {
                Movie* oldMovie = disc.movie;
                if ([movie isNotEqualTo:oldMovie]) {
                    disc.movie = movie;
                    if (oldMovie) {
                        [self _deleteMovieIfNoMediaRemainForAnyDisc:oldMovie];
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
            NSString* aspectRatio = [movieInfo objectForKey:@"aspectRatio"];
            if ([aspectRatio length]) {
                movie.aspectRatio = aspectRatio;
            }
            NSString* review = [movieInfo objectForKey:@"review"];
            if ([review length]) {
                movie.review = review;
            }
            NSString* synopsis = [movieInfo objectForKey:@"synopsis"];
            if ([synopsis length]) {
                movie.synopsis = synopsis;
            }
            NSString* title = [movieInfo objectForKey:@"title"];
            if ([title length]) {
                movie.title = title;
            }
            NSString* genre = [movieInfo objectForKey:@"genre"];
            if ([genre length]) {
                movie.genre = genre;
            }
            NSString* studio = [movieInfo objectForKey:@"studio"];
            if ([studio length]) {
                movie.studio = studio;
            }
            NSNumber* productionYear = [movieInfo objectForKey:@"productionYear"];
            if (productionYear) {
                movie.productionYear = productionYear;
            }
            NSNumber* runningTime = [movieInfo objectForKey:@"runningTime"];
            if (runningTime) {
                movie.runningTime = runningTime;
            }
            NSNumber* regionCode = [movieInfo objectForKey:@"regionCode"];
            if (regionCode) {
                movie.regionCode = regionCode;
            }
            NSString* theatricalReleaseDateAsString = [movieInfo objectForKey:@"theatricalReleaseDate"];
            if ([theatricalReleaseDateAsString length]) {
                movie.theatricalReleaseDate = [dateFormatter dateFromString:theatricalReleaseDateAsString];
            }
            NSString* releaseDateAsString = [movieInfo objectForKey:@"releaseDate"];
            if ([releaseDateAsString length]) {
                movie.releaseDate = [dateFormatter dateFromString:releaseDateAsString];
            }
            
            
            /*  If there is a "discs" dictionary present, enumerate it's keys,
             *  creating disc objects and associating them with the movie that
             *  we're attaching ourselves to.
             */
            NSDictionary* discInfo = [movieInfo objectForKey:@"discs"];
            for (NSString* discInfoFingerprint in discInfo) {
                NSDictionary* otherDiscInfo = [discInfo objectForKey:discInfoFingerprint];
                Disc* disc = [self _findDiscByFingerprint:discInfoFingerprint];
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
                        [self _deleteMovieIfNoMediaRemainForAnyDisc:movieForDisc];
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
                Media* media = [self _findMediaByEngine:engine URL:url];
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
    NSNotificationCenter* notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self name:NSManagedObjectContextDidSaveNotification object:managedObjectContext];
    [managedObjectContext save:nil];
    [notificationCenter addObserver:self selector:@selector(_coreDataDidSaveNotification:) name:NSManagedObjectContextDidSaveNotification object:managedObjectContext];
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
    Engine* engine = [self _findEngineByNetServiceName:[netService name]];
    NSAssert(engine, @"no engine?");
    NSDictionary* rawData = [NSNetService dictionaryFromTXTRecordData:[netService TXTRecordData]];
    NSString* uuid = [[[NSString alloc] initWithData:[rawData objectForKey:@"UUID"] encoding:NSUTF8StringEncoding] autorelease];
    NSString* name = [[[NSString alloc] initWithData:[rawData objectForKey:@"Name"] encoding:NSUTF8StringEncoding] autorelease];
    
    engine.name = name;
    engine.uuid = uuid;
    engine.status = @"Resolved";
    engine.netServiceName = [netService name];
    [managedObjectContext save:nil];
    
    if (YES || [uuid isEqualToString:localMachineUUID]) {
        [self connectEngine:engine];
    }
}

@end


#pragma mark -
@implementation EngineController (NSNetServiceBrowserDelegate)

- (void) netServiceBrowser:(NSNetServiceBrowser*)netServiceBrowser didFindService:(NSNetService*)netService moreComing:(BOOL)moreComing
{
    [netServiceByName setObject:netService forKey:[netService name]];

    Engine* engine = [[Engine alloc] initWithEntity:engineDesc insertIntoManagedObjectContext:managedObjectContext];
    engine.netServiceName = [netService name];
    engine.name = [netService name];
    engine.status = @"Resolving";
    [managedObjectContext save:nil];
    
    [netService setDelegate:self];
    [netService scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    [netService resolveWithTimeout:5.0];
}

- (void) netServiceBrowser:(NSNetServiceBrowser*)netServiceBrowser didRemoveService:(NSNetService*)netService moreComing:(BOOL)moreComing 
{
    [netService stop];
    [netService removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    [netServiceByName removeObjectForKey:[netService name]];

    Engine* engine = [self _findEngineByNetServiceName:[netService name]];
    NSAssert(engine, @"no engine?");
    [self disconnectEngine:engine];
    
    [managedObjectContext deleteObject:engine];
    [managedObjectContext save:nil];
}

@end
