#import "EngineController.h"
#import "MessageProtocol.h"
#import "Media.h"
#import "Movie.h"
#import "Disc.h"
#import "BoxArt.h"
#import "Engine.h"
#import "Activity.h"
#import "Query.h"
#import "ImageQuery.h"
#import "JSONQuery.h"

#import <Toolkit/Toolkit.h>

#import <unistd.h>
#import <netinet/ip.h>
#import <netinet/ip6.h>

NSString* const kLoadingBoxArtActivityName = @"LoadingCoverArtActivity";
NSString* const kLoadingDiscInfo = @"LoadingDiscInfo";

@interface EngineController (Private)
- (Disc*) _findDiscByFingerprint:(NSString*)fingerprint;
- (BoxArt*) _findBoxArtByURL:(NSString*)url;
- (Movie*) _findMovieByGTIN:(NSString*)gtin;
- (Media*) _findMediaByEngine:(Engine*)engine tag:(NSString*)tag;
- (Engine*) _findEngineByUUID:(NSString*)UUID;
- (Engine*) _findEngineByNetServiceName:(NSString*)netServiceName;
- (void) _deleteMovieIfNoMediaRemainForAnyDisc:(Movie*)movie;
- (NSString*) _getMovieRating:(NSDictionary*)movieInfo;
@end

@interface EngineController (ImageQueryDelegate)
- (void) imageQuery:(ImageQuery*)query didFailWithError:(NSError*)error userInfo:(id)userInfo;
- (void) imageQuery:(ImageQuery*)query didReceiveData:(NSData*)data ofType:(NSString*)mimeType userInfo:(id)userInfo;
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

- (void) removeOldEnginesAndAssociatedDiscsAndMedia 
{
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:engineEntity];
    NSArray* enginesToDelete = [managedObjectContext executeFetchRequest:fetchRequest error:nil];
    if ([enginesToDelete count]) {
        for (Engine* engine in enginesToDelete) {
            for (Media* media in [engine allMedia]) {
                [managedObjectContext deleteObject:media];
            }
            [managedObjectContext deleteObject:engine];
        }
        [managedObjectContext save:nil];
    }
    [fetchRequest release];
}

- (void) removeFailedBoxArt
{
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:boxArtEntity];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"state != 'Loaded'"]];
    NSArray* results = [managedObjectContext executeFetchRequest:fetchRequest error:nil];
    if ([results count]) {
        for (BoxArt* boxArt in results) {
            [managedObjectContext deleteObject:boxArt];
        }
        [managedObjectContext save:nil];
    }
    [fetchRequest release];
}

- (id) initWithManagedObjectContext:(NSManagedObjectContext*)_managedObjectContext 
{
    if (self = [super init]) {
        netServiceByName = [[NSMutableDictionary alloc] init];
        protocolsByUUID = [[NSMutableDictionary alloc] init];
        managedObjectContext = [_managedObjectContext retain];
        dateFormatter = [[NSDateFormatter alloc] initWithDateFormat:@"%Y-%m-%d" allowNaturalLanguage:NO];

        /*  Grab references to some commonly used entity descriptions.
         */
        engineEntity = [[NSEntityDescription entityForName:@"Engine" inManagedObjectContext:managedObjectContext] retain];
        mediaEntity = [[NSEntityDescription entityForName:@"Media" inManagedObjectContext:managedObjectContext] retain];
        discEntity = [[NSEntityDescription entityForName:@"Disc" inManagedObjectContext:managedObjectContext] retain];
        movieEntity = [[NSEntityDescription entityForName:@"Movie" inManagedObjectContext:managedObjectContext] retain];
        boxArtEntity = [[NSEntityDescription entityForName:@"BoxArt" inManagedObjectContext:managedObjectContext] retain];

        [self removeOldEnginesAndAssociatedDiscsAndMedia];
        [self removeFailedBoxArt];
        
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
    [engineEntity release];
    [mediaEntity release];
    [discEntity release];
    [movieEntity release];
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
    MessageProtocol* protocol = [protocolsByUUID objectForKey:engine.uuid];
    if (protocol) {
        return YES;
    }
    @synchronized (managedObjectContext) {
        NSNetService* netService = [netServiceByName objectForKey:engine.netServiceName];
        NSAssert(netService, @"no net service?");
        
        engine.status = @"Connecting";
        [managedObjectContext save:nil];
        for (NSData* address in [netService addresses]) {
            const struct sockaddr* a = [address bytes];
            int fd = socket(a->sa_family, SOCK_STREAM, 0);
            if (fd >= 0) {
                if (0 == connect(fd, a, a->sa_len)) {
                    size_t sendBufferSize = 512 * 0x400;
                    size_t receiveBufferSize = 512 * 0x400;
                    setsockopt(fd, SOL_SOCKET, SO_SNDBUF, (void*)&sendBufferSize, sizeof(sendBufferSize));
                    setsockopt(fd, SOL_SOCKET, SO_RCVBUF, (void*)&receiveBufferSize, sizeof(receiveBufferSize));
                    
                    NSFileHandle* fileHandle = [[NSFileHandle alloc] initWithFileDescriptor:fd closeOnDealloc:YES];
                    protocol = [MessageProtocol protocolWithDelegate:self fileHandleForReading:fileHandle fileHandleForWriting:fileHandle];
                    protocol.userInfo = [[engine objectID] retain];
                    [protocolsByUUID setObject:protocol forKey:engine.uuid];
                    [fileHandle release];
                    break;
                } else {
                    close(fd);
                }
            }
        }
        
        if (protocol) {
            engine.status = @"Connected";
        } else {
            engine.status = @"Not Connected";
        }
        [managedObjectContext save:nil];
    }
    return protocol != nil;
}

- (void) disconnectEngine:(Engine*)engine
{
    NSAssert(engine, @"no engine?");
    @synchronized (managedObjectContext) {
        engine.status = @"Disconnecting";
        [managedObjectContext save:nil];
        
        MessageProtocol* protocol = [protocolsByUUID objectForKey:engine.uuid];
        if (protocol) {
            NSManagedObjectID* objectID = protocol.userInfo;
            NSAssert([objectID isEqual:engine.objectID], @"Why don't these match?");
            @try {
                [protocol close];
            } @finally {
                [protocolsByUUID removeObjectForKey:engine.uuid];
            }
            [objectID release];
        }
        
        engine.status = @"Not Connected";
        [managedObjectContext save:nil];

        BOOL isLocalMachine = [localMachineUUID isEqualToString:engine.uuid];
        for (Media* media in [engine allMedia]) {
            if (isLocalMachine) {
                media.isAvailable = (id)kCFBooleanFalse;
            } else {
                Disc* disc = media.disc;
                [managedObjectContext deleteObject:media];
                Movie* movie = disc.movie;
                NSAssert(movie, @"wtf?");
                int zeroCount = 0;
                int total = 0;
                for (Disc* otherDisc in movie.allDiscs) {
                    int count = [otherDisc.localMediaCount intValue];
                    zeroCount += (disc == otherDisc && (count == 1)) || (count == 0);
                    total++;
                }
                if (zeroCount == total) {
                    for (Disc* disc in movie.allDiscs) {
                        [managedObjectContext deleteObject:disc];
                    }
                    [managedObjectContext deleteObject:movie];
                }
            }
        }
        NSError* error = nil;
        [managedObjectContext save:&error];
        NSLog(@"%@ -- %@", error, error.userInfo);
    }
}

@end


#pragma mark -
@implementation EngineController (Private)

- (BoxArt*) _findBoxArtByURL:(NSString*)url
{
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:boxArtEntity];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"url == %@", url]];
    NSError* error = nil;
    NSArray* results = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    [fetchRequest release];
    if (!error && [results count]) {
        return [results objectAtIndex:0];
    }
    return nil;
}

- (Disc*) _findDiscByFingerprint:(NSString*)fingerprint
{
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:discEntity];
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
    [fetchRequest setEntity:movieEntity];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"gtin == %@", gtin]]; 
    NSError* error = nil;
    NSArray* results = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    [fetchRequest release];
    if (!error && [results count]) {
        return [results objectAtIndex:0];
    }
    return nil;
}

- (Media*) _findMediaByEngine:(Engine*)engine tag:(NSString*)tag
{
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:mediaEntity];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"engine == %@ && tag == %@", engine, tag]]; 
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
    [fetchRequest setEntity:engineEntity];
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
    [fetchRequest setEntity:engineEntity];
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
    [fetchRequest setEntity:discEntity];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"movie == %@ && allMedia.@count == 0", movie]];
    NSError* error = nil;
    NSArray* results = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    [fetchRequest release];
    if (!error && [results count] == [movie.allDiscs count]) {
        [managedObjectContext deleteObject:movie];
    }
}

- (NSString*) _getMovieRating:(NSDictionary*)movieInfo
{
    NSString* audienceRating = [movieInfo objectForKey:@"audienceRating"];
    if ([audienceRating length]) {
        return audienceRating;
    }
    audienceRating = [movieInfo objectForKey:@"audience_rating"];
    if ([audienceRating length]) {
        return audienceRating;
    }
    
#ifndef NO_HACKS
    NSString* synopsis = [movieInfo objectForKey:@"synopsis"];
    if ([synopsis length]) {
        NSRange locationOfRating = [synopsis rangeOfString:@"Rating:"];
        if (locationOfRating.location != NSNotFound) {
            NSString* rating = [synopsis substringFromIndex:locationOfRating.location + locationOfRating.length];
            rating = [rating substringToIndex:[rating rangeOfString:@" "].location];
            return rating;                    
        }
    } 
#endif
    
    return @"N/A";
}

@end

#pragma mark -
@implementation EngineController (JSONQueryDelegate)

- (void) JSONQuery:(JSONQuery*)query didFailWithError:(NSError*)error userInfo:(id)userInfo
{
    Activity* activity = userInfo;
    if (activity.name == kLoadingDiscInfo) {
        [activity terminate];
    }
}

- (void) JSONQuery:(JSONQuery*)query didReceiveObject:(id)object userInfo:(id)userInfo
{
    Activity* activity = userInfo;
    @synchronized (managedObjectContext) {
        @try {
            NSDictionary* info = object;
            NSDictionary* movieInfo = [info objectForKey:@"movie"];
            
            /*  Find the disc that's represented by our fingerprint.
             */
            Media* media = (Media*)[managedObjectContext objectWithID:activity.userInfo]; 
            if (media) {
                Disc* disc = media.disc;
                
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
                        movie = [[[Movie alloc] initWithEntity:movieEntity insertIntoManagedObjectContext:managedObjectContext] autorelease];
                    }
                    if (gtin) {
                        movie.gtin = gtin;
                    }
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
                NSNumber* starRating = [movieInfo objectForKey:@"starRating"];
                if (starRating) {
                    movie.starRating = starRating;
                }
                NSString* theatricalReleaseDateAsString = [movieInfo objectForKey:@"theatricalReleaseDate"];
                if ([theatricalReleaseDateAsString length]) {
                    movie.theatricalReleaseDate = [dateFormatter dateFromString:theatricalReleaseDateAsString];
                }
                NSString* releaseDateAsString = [movieInfo objectForKey:@"releaseDate"];
                if ([releaseDateAsString length]) {
                    movie.releaseDate = [dateFormatter dateFromString:releaseDateAsString];
                }
                movie.rating = [self _getMovieRating:movieInfo];

                /*  If there is a "discs" dictionary present, enumerate it's keys,
                 *  creating disc objects and associating them with the movie that
                 *  we're attaching ourselves to.
                 */
                NSDictionary* discInfo = [movieInfo objectForKey:@"discs"];
                for (NSString* discInfoFingerprint in discInfo) {
                    NSDictionary* otherDiscInfo = [discInfo objectForKey:discInfoFingerprint];
                    Disc* disc = [self _findDiscByFingerprint:discInfoFingerprint];
                    if (!disc) {
                        disc = [[[Disc alloc] initWithEntity:discEntity insertIntoManagedObjectContext:managedObjectContext] autorelease];
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
                    NSString* synopsis = [otherDiscInfo objectForKey:@"description"];
                    if ([synopsis length]) {
                        disc.synopsis = synopsis;
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
        } @catch (id exception) {
            [managedObjectContext rollback];
        } @finally {
            [activity terminate];
        }
    }
}

@end

#pragma mark -
@implementation EngineController (ImageQueryDelegate)

- (void) imageQuery:(ImageQuery*)query didFailWithError:(NSError*)error userInfo:(id)userInfo
{
    @synchronized (managedObjectContext) {
        Activity* activity = userInfo;
        @try {
            BoxArt* boxArt = (BoxArt*)[managedObjectContext objectRegisteredForID:activity.userInfo];
            if (boxArt) {
                NSString* state = error ? [error description] : @"Error";
                boxArt.state = state;

                if ([boxArt validateForUpdate:nil]) {
                    [managedObjectContext save:nil];
                }
            }
        } @catch (id exception) {
            [managedObjectContext rollback];
        } @finally {
            [activity terminate];
        }
    }
}

- (void) imageQuery:(ImageQuery*)query didReceiveData:(NSData*)data ofType:(NSString*)mimeType userInfo:(id)userInfo
{
    @synchronized (managedObjectContext) {
        Activity* activity = userInfo;
        @try {
            BoxArt* boxArt = (BoxArt*)[managedObjectContext objectRegisteredForID:activity.userInfo];
            if (boxArt) {
                NSString* type = [(id)UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, (CFStringRef)mimeType, CFSTR("public.image")) autorelease];
                boxArt.type = type;
                boxArt.state = @"Loaded";
                boxArt.imageData = data;
                
                for (Disc* disc in [boxArt allDiscs]) {
                    if (!disc.movie.boxArt) {
                        disc.movie.boxArt = boxArt;
                    }
                }
                
                if ([boxArt validateForUpdate:nil]) {
                    [managedObjectContext save:nil];
                }
            }
        } @catch (id exception) {
            NSLog(@"%@", exception);
            [managedObjectContext rollback];
        } @finally {
            [activity terminate];
        }
    }
}

@end


#pragma mark -
@implementation EngineController (CoreData)

- (void) _coreDataDidSaveNotification:(NSNotification*)notification
{
    for (NSManagedObject* managedObject in [[notification userInfo] objectForKey:NSUpdatedObjectsKey]) {
        NSEntityDescription* const entityDescription = [managedObject entity];
        if (entityDescription == movieEntity) {
            NSLog(@"%@", managedObject);
            NSLog(@"%@", [[managedObject changedValues] allKeys]);
        } else if (entityDescription == discEntity) {
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
    @synchronized (managedObjectContext) {
        NSManagedObjectID* objectID = protocol.userInfo;
        Engine* engine = (Engine*)[managedObjectContext objectWithID:objectID];
        if (engine) {
            [protocolsByUUID removeObjectForKey:engine.uuid];
            [self disconnectEngine:engine];
        }
    }
}

- (void) protocol:(MessageProtocol*)protocol didReceiveMessage:(NSDictionary*)message 
{
    @synchronized (managedObjectContext) {
        NSManagedObjectID* objectID = protocol.userInfo;
        Engine* engine = (Engine*)[managedObjectContext objectWithID:objectID];
        if (!engine) {
            return;
        }
        BOOL isLocalMachine = [localMachineUUID isEqualToString:engine.uuid]; 
        
        /*  Add
         */
        NSDictionary* add = [message objectForKey:@"add"];
        if (add && [add isKindOfClass:[NSDictionary class]]) {
            for (NSString* tag in add) {
                NSDictionary* info = [add objectForKey:tag];
                
                NSString* fingerprint = [info objectForKey:@"fingerprint"];
                NSNumber* isAvailable = [info objectForKey:@"isAvailable"];
                NSString* pathToFile = [info objectForKey:@"pathToFile"];
                NSString* type = [info objectForKey:@"type"];
                NSString* title = [[pathToFile lastPathComponent] stringByDeletingPathExtension];

                Disc* disc = [self _findDiscByFingerprint:fingerprint];
                if (!disc) {
                    disc = [[[Disc alloc] initWithEntity:discEntity insertIntoManagedObjectContext:managedObjectContext] autorelease];
                    disc.fingerprint = fingerprint;
                }

                Movie* movie = disc.movie;
                if (!disc.movie) {
                    movie = [[[Movie alloc] initWithEntity:movieEntity insertIntoManagedObjectContext:managedObjectContext] autorelease];
                    disc.movie = movie;
                    movie.title = title;
                }
                
                Media* media = [self _findMediaByEngine:engine tag:tag];
                if (!media) {
                    media = [[[Media alloc] initWithEntity:mediaEntity insertIntoManagedObjectContext:managedObjectContext] autorelease];
                    media.tag = tag;
                    media.engine = engine;
                }
                media.isAvailable = isAvailable;
                media.isLocal = (id)(isLocalMachine ? kCFBooleanTrue : kCFBooleanFalse);
                media.disc = disc;
                media.type = type;
                if (isLocalMachine) {
                    media.pathToFile = pathToFile;
                }

                /*  Make sure that we get permanent IDs for the things we just 
                 *  made.
                 */
                [managedObjectContext obtainPermanentIDsForObjects:[NSArray arrayWithObjects:media, disc, movie, nil] error:nil];
                
                /*  Fire off a query to get additional info, if necessary.
                 */
                NSString* infoURL = [info objectForKey:@"infoURL"];
                if (infoURL && !movie.metadataAcceptedDate) {
                    [JSONQuery JSONQueryWithURL:[NSURL URLWithString:infoURL] delegate:self userInfo:[Activity activityWithName:kLoadingDiscInfo userInfo:media.objectID] startImmediately:YES];
                }
                
                /*  Fire off a query to get box art, if necessary.
                 */
                NSString* frontCoverURL = [info objectForKey:@"frontCoverURL"];
                if (frontCoverURL && !disc.boxArt) {
                    BoxArt* boxArt = [self _findBoxArtByURL:frontCoverURL];
                    if (!boxArt) {
                        boxArt = [[BoxArt alloc] initWithEntity:boxArtEntity insertIntoManagedObjectContext:managedObjectContext];
                        boxArt.url = frontCoverURL;
                        boxArt.state = @"Loading";
                        [managedObjectContext obtainPermanentIDsForObjects:[NSArray arrayWithObjects:boxArt, nil] error:nil];
                        [ImageQuery imageQueryWithURL:[NSURL URLWithString:frontCoverURL] delegate:self userInfo:[Activity activityWithName:kLoadingBoxArtActivityName userInfo:boxArt.objectID] startImmediately:YES];
                    }
                    disc.boxArt = boxArt;
                }
            }
        }

        /*  Update
         */
        NSDictionary* update = [message objectForKey:@"update"];
        if (update && [update isKindOfClass:[NSDictionary class]]) {
            for (NSString* tag in update) {
                NSDictionary* info = [add objectForKey:tag];
                Media* media = [self _findMediaByEngine:engine tag:tag];
                NSAssert(media, @"wtf?");

                NSString* fingerprint = [info objectForKey:@"fingerprint"];
                Disc* disc = media.disc;
                if (fingerprint && ![fingerprint isEqualToString:disc.fingerprint]) {
                    Disc* disc = [self _findDiscByFingerprint:fingerprint];
                    if (!disc) {
                        disc = [[[Disc alloc] initWithEntity:discEntity insertIntoManagedObjectContext:managedObjectContext] autorelease];
                        disc.fingerprint = fingerprint;
                    }
                    media.disc = disc;
                }

                NSNumber* isAvailable = [info objectForKey:@"isAvailable"];
                if (isAvailable && [isAvailable isNotEqualTo:media.isAvailable]) {
                    media.isAvailable = isAvailable;
                }
                
                NSString* type = [info objectForKey:@"type"];
                if (type && [type isNotEqualTo:media.type]) {
                    media.type = type;
                }

                NSString* pathToFile = [info objectForKey:@"pathToFile"];
                if (pathToFile && [pathToFile isNotEqualTo:media.pathToFile]) {
                    media.pathToFile = pathToFile;
                }
                
                Movie* movie = disc.movie;
                if (!disc.movie) {
                    movie = [[[Movie alloc] initWithEntity:movieEntity insertIntoManagedObjectContext:managedObjectContext] autorelease];
                    disc.movie = movie;
                    movie.title =  [[pathToFile lastPathComponent] stringByDeletingPathExtension];
                }
                
                /*  Fire off a query to get additional info, if necessary.
                 */
                NSString* infoURL = [info objectForKey:@"infoURL"];
                if (infoURL && !movie.metadataAcceptedDate) {
                    [JSONQuery JSONQueryWithURL:[NSURL URLWithString:infoURL] delegate:self userInfo:[Activity activityWithName:kLoadingDiscInfo userInfo:media.objectID] startImmediately:YES];
                }
                
                /*  Fire off a query to get box art, if necessary.
                 */
                NSString* frontCoverURL = [info objectForKey:@"frontCoverURL"];
                if (frontCoverURL && !disc.boxArt) {
                    BoxArt* boxArt = [self _findBoxArtByURL:frontCoverURL];
                    if (!boxArt) {
                        boxArt = [[BoxArt alloc] initWithEntity:boxArtEntity insertIntoManagedObjectContext:managedObjectContext];
                        boxArt.url = frontCoverURL;
                        boxArt.state = @"Loading";
                        [managedObjectContext obtainPermanentIDsForObjects:[NSArray arrayWithObjects:boxArt, nil] error:nil];
                        [ImageQuery imageQueryWithURL:[NSURL URLWithString:frontCoverURL] delegate:self userInfo:[Activity activityWithName:kLoadingBoxArtActivityName userInfo:boxArt.objectID] startImmediately:YES];
                    }
                    disc.boxArt = boxArt;
                }
            }
        }
        
        /*  Delete
         */
        NSDictionary* delete = [message objectForKey:@"delete"];
        if (delete && [delete isKindOfClass:[NSArray class]]) {
            for (NSString* tag in delete) {
                Media* media = [self _findMediaByEngine:engine tag:tag];
                if (!media) {
                    continue;
                }
                if (isLocalMachine) {
                    media.isAvailable = (id)kCFBooleanFalse;
                } else {
                    Disc* disc = media.disc;
                    [managedObjectContext deleteObject:media];
                    Movie* movie = disc.movie;
                    NSAssert(movie, @"wtf?");
                    int zeroCount = 0;
                    int total = 0;
                    for (Disc* otherDisc in movie.allDiscs) {
                        int count = [otherDisc.localMediaCount intValue];
                        zeroCount += (disc == otherDisc && (count == 1)) || (count == 0);
                        total++;
                    }
                    if (zeroCount == total) {
                        for (Disc* disc in movie.allDiscs) {
                            [managedObjectContext deleteObject:disc];
                        }
                        [managedObjectContext deleteObject:movie];
                    }
                }
            }
        }
        
        /*  Persist out our changes.
         */
        NSError* error = nil;
        [managedObjectContext save:&error];
        if (error) {
            NSLog(@"%s -- %@ (%@)", __PRETTY_FUNCTION__, error, error.userInfo);
        }
    }
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
    NSAssert(name, @"no name?");
    NSAssert(uuid, @"no uuid?");
    
    Engine* engine = nil;
    @synchronized (managedObjectContext) {
        engine = [self _findEngineByNetServiceName:[netService name]];
        NSAssert(engine, @"no engine?");
        engine.name = name;
        engine.uuid = uuid;
        engine.status = @"Resolved";
        engine.netServiceName = [netService name];
        [managedObjectContext save:nil];
    }
    
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

    Engine* engine = nil;
    @synchronized (managedObjectContext) {
        engine = [self _findEngineByNetServiceName:[netService name]];
        if (!engine) {
            engine = [[Engine alloc] initWithEntity:engineEntity insertIntoManagedObjectContext:managedObjectContext];
            [managedObjectContext obtainPermanentIDsForObjects:[NSArray arrayWithObject:engine] error:nil];
        }
        engine.name = [netService name];
        engine.netServiceName = [netService name];
        engine.status = @"Resolving";
        [managedObjectContext save:nil];
    }
    
    [netService setDelegate:self];
    [netService scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    [netService resolveWithTimeout:5.0];
}

- (void) netServiceBrowser:(NSNetServiceBrowser*)netServiceBrowser didRemoveService:(NSNetService*)netService moreComing:(BOOL)moreComing 
{
    [netService stop];
    [netService removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    [netServiceByName removeObjectForKey:[netService name]];

    @synchronized (managedObjectContext) {
        Engine* engine = [self _findEngineByNetServiceName:[netService name]];
        if (engine) {
            [managedObjectContext deleteObject:engine];
            NSError* error = nil;
            [managedObjectContext save:&error];
            NSLog(@"%@ -- %@", error, error.userInfo);
        }
    }
}

@end
