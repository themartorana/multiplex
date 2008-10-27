#import "Engine.h"
#import "Model/Disc.h"
#import "Model/MediaLocator.h"
#import "Queries/AmazonQuery.h"
#import "Queries/ImageQuery.h"

#import <DiscIdentKit/DiscIdentKit.h>
#import <CoreData/CoreData.h>
#import <Toolkit/Toolkit.h>
#import <JSONKit/JSONKit.h>
#import <SystemConfiguration/SCDynamicStore.h>

#import <netinet/ip.h>
#import <netinet/ip6.h>
#import <sys/param.h>
#import <sys/mount.h>

static NSString* const kAmazonAccessKey = @"01Y2NSCMDJ3VJXTCBTR2";

@interface Engine (Private)

- (void) _loadMediaSourcePlugins;
- (void) _stopMediaSourcePlugins;
- (void) _republishNetService;
- (NSString*) _frontCoverURLForFingerprint:(NSString*)fingeprint;

@end

@interface Engine (NSNetServiceDelegate)
- (void) netService:(NSNetService*)netService didNotPublish:(NSDictionary*)errorInfo;
- (void) netServiceDidPublish:(NSNetService*)netService;
@end

@implementation Engine

+ (void) initialize
{
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
        nil
    ]];
}

- (id) init
{
    if (self = [super init]) {
        mediaFileByTag = [[NSMutableDictionary alloc] init];
        infoDictionariesByFingerprint = [[NSMutableDictionary alloc] init];
        protocols = [[NSMutableArray alloc] init];
        mediaSources = [[NSMutableArray alloc] init];
        
        static CFStringRef const kEngineMachineIdKey = CFSTR("machine-id");
        static CFStringRef const kEngineMachineNameKey = CFSTR("machine-name");
        static CFStringRef const kEngineAppDomain = CFSTR("com.multiplexapp.Engine");
        machineId = (NSString*)CFPreferencesCopyValue(kEngineMachineIdKey, kEngineAppDomain, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
        if (!machineId) {
            machineId = [[NSString stringWithUUID] retain];
            CFPreferencesSetValue(kEngineMachineIdKey, (CFStringRef)machineId, kEngineAppDomain, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
            CFPreferencesSynchronize(kEngineAppDomain, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
        }
        machineName = (NSString*)CFPreferencesCopyValue(kEngineMachineNameKey, kEngineAppDomain, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
        if (!machineName) {
            machineName = [[NSString alloc] initWithFormat:@"%@'s Movies", NSFullUserName()];
        }
        
        txtData = [[NSMutableDictionary dictionaryWithObjectsAndKeys:
            [machineId dataUsingEncoding:NSUTF8StringEncoding], @"UUID",
            [machineName dataUsingEncoding:NSUTF8StringEncoding], @"Name",
            [[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"] dataUsingEncoding:NSUTF8StringEncoding], @"Version",
            nil
        ] retain];
    }
    return self;
}

- (void) dealloc
{
    [mediaFileByTag release];
    [infoDictionariesByFingerprint release];
    [mediaSources release];
    [machineId release];
    [machineName release];
    [txtData release];
    [protocols release];
    [super dealloc];
}

- (void) run
{
    NSSocketPort* serverSocket = nil;
    NSFileHandle* serverHandle = nil;
    
    @try {
        /*  Add observers for defaults that we care about.
         */
        NSUserDefaultsController* defaultsController = [NSUserDefaultsController sharedUserDefaultsController];
        [defaultsController addObserver:self forKeyPath:@"values.machine-name" options:NSKeyValueObservingOptionNew context:nil];

        {
            managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Engine" ofType:@"mom"]]];
            persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:managedObjectModel];
            [persistentStoreCoordinator addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:nil options:nil error:nil];
            managedObjectContext = [[NSManagedObjectContext alloc] init];
            [managedObjectContext setPersistentStoreCoordinator:persistentStoreCoordinator];
            
            discEntity = [[NSEntityDescription entityForName:@"Disc" inManagedObjectContext:managedObjectContext] retain];
            mediaLocatorEntity = [[NSEntityDescription entityForName:@"MediaLocator" inManagedObjectContext:managedObjectContext] retain];
        }
        
        {
            struct sockaddr_in6 sin6;
            sin6.sin6_len = sizeof(sin6);
            sin6.sin6_family = AF_INET6;
            sin6.sin6_flowinfo = 0;
            sin6.sin6_port = 0;
            sin6.sin6_addr = in6addr_any;
            NSSocketPort* serverSocket = [[NSSocketPort alloc] initWithProtocolFamily:PF_INET6 socketType:SOCK_STREAM protocol:0 address:[NSData dataWithBytesNoCopy:&sin6 length:sizeof(sin6) freeWhenDone:NO]];
            struct sockaddr_in6* psin6 = (struct sockaddr_in6*)[[serverSocket address] bytes];
            baseImageURL = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"http://%@.local:%d/", SCDynamicStoreCopyLocalHostName(NULL,NULL), ntohs(psin6->sin6_port)]];
            NSLog(@"%@", baseImageURL);
            imageServer = [[HTTPServer alloc] initWithSocketPort:serverSocket delegate:self];
        }
        
        /*  Setup our socket to listen on, and begin accepting connections.
         */
        {
            struct sockaddr_in6 sin6;
            sin6.sin6_len = sizeof(sin6);
            sin6.sin6_family = AF_INET6;
            sin6.sin6_flowinfo = 0;
            sin6.sin6_port = 0;
            sin6.sin6_addr = in6addr_any;
            serverSocket = [[NSSocketPort alloc] initWithProtocolFamily:PF_INET6 socketType:SOCK_STREAM protocol:0 address:[NSData dataWithBytesNoCopy:&sin6 length:sizeof(sin6) freeWhenDone:NO]];
            struct sockaddr_in6* psin6 = (struct sockaddr_in6*)[[serverSocket address] bytes];
            networkPort = ntohs(psin6->sin6_port);
            serverHandle = [[NSFileHandle alloc] initWithFileDescriptor:[serverSocket socket] closeOnDealloc:YES];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(acceptConnection:) name:NSFileHandleConnectionAcceptedNotification object:serverHandle];
            [serverHandle acceptConnectionInBackgroundAndNotify];
            [self _republishNetService];
            NSLog(@"Listening on ip6 port: %d", networkPort);
        }

        /*  Load and start our MediaFile Source plugins
         */
        [self _loadMediaSourcePlugins];        

        /*  Process our message loop unil we're told to stop.
         */
        [super run];
    } @catch (id exception) {
        NSLog(@"Exception occurred while initializing; quitting. -- %@", exception);
    } @finally {
        [serverSocket release];
        serverSocket = nil;
        
        [serverHandle closeFile];
        serverHandle = nil;

        [netService stop];
        [netService release];
        netService = nil;
        
        [self _stopMediaSourcePlugins];
    }
}

- (void) _loadMediaSourcePlugins
{
    /*  Determine the folder we'll search for ".mediasource" plugins.  This is 
     *  a little complicated due to the fact that we load from one place under
     *  the debugger, and another when we're running under Multiplex.
     */
    NSString* baseFolder = [[[NSBundle mainBundle] executablePath] stringByDeletingLastPathComponent];
    if ([[baseFolder lastPathComponent] isEqualToString:@"Resources"]) {
        baseFolder = [[baseFolder stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"Plugins"];
    }
    
    /*  Search for ".mediasource" plugins, loading them and checking that they
     *  conform to our MediaSource protocol before we fire up an instance and
     *  try to connect ourselves to it.
     */
    NSLog(@"Loading Plugins (%@):", baseFolder);
    for (NSString* pluginFile in [[NSFileManager defaultManager] directoryContentsAtPath:baseFolder]) {
        if ([pluginFile hasSuffix:@".mediasource"]) {
            NSError* error = nil;
            NSBundle* plugin = [NSBundle bundleWithPath:[baseFolder stringByAppendingPathComponent:pluginFile]];
            NSLog(@"  - Loading plugin: %@", pluginFile);
            if (![plugin loadAndReturnError:&error]) {
                NSLog(@"    - Error loading plugin (%@) -- %@", pluginFile, error);
            } else {
                id<MediaFileSource> mediaSource = nil;
                Class principalClass = [plugin principalClass];
                if ([principalClass conformsToProtocol:@protocol(MediaFileSource)]) {
                    @try {
                        /*  Set ourselves as the media source's delegate, and 
                         *  then start it up.
                         */
                        mediaSource = [[principalClass alloc] init]; 
                        [mediaSource setDelegate:self];
                        [mediaSource start];
                        
                        [mediaSources addObject:mediaSource];
                    } @catch (id exception) {
                        NSLog(@"    - Exception occurred while starting mediaSource -- %@", exception);
                        mediaSource = nil;
                    }
                }
                if (!mediaSource) {
                    [plugin unload];
                }
            }
        }
    }
}

- (void) _stopMediaSourcePlugins
{
    for (id<MediaFileSource> mediaSource in mediaSources) {
        @try {
            [mediaSource stop];
        } @catch (id exception) {
            NSLog(@"Exception occurred while stopping mediaSource -- %@", exception);
        }
    }
}

- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void *)context
{  
    BOOL republishServiceData = NO;
    
    if ([keyPath isEqual:@"values.machine-name"]) {
        [txtData setObject:[[change objectForKey:NSKeyValueChangeNewKey] dataUsingEncoding:NSUTF8StringEncoding] forKey:@"Name"];
        republishServiceData = YES;
    }
    
    if (republishServiceData) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(republishNetService) object:nil];
        [self performSelector:@selector(republishNetService) withObject:nil afterDelay:1.0];
    }
}

- (void) _republishNetService
{
    if (netService && ![[netService name] isEqualTo:machineName]) {
        [netService stop];
        [netService release];
        netService = nil;
    }
    if (!netService) {
        netService = [[NSNetService alloc] initWithDomain:@"local." type:@"_com_multiplexapp_Engine._tcp" name:machineName port:networkPort];
        netService.delegate = self;
    }
    [netService setTXTRecordData:[NSNetService dataFromTXTRecordDictionary:txtData]];
    [netService publishWithOptions:NSNetServiceNoAutoRename];
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

- (MediaLocator*) _findMediaLocatorForFileSystemID:(NSString*)fileSystemID relativePath:(NSString*)relativePath
{
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:mediaLocatorEntity];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"fileSystemID == %@ and relativePath == %@", fileSystemID, relativePath]];
    NSError* error = nil;
    NSArray* results = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    [fetchRequest release];
    if (!error && [results count]) {
        return [results objectAtIndex:0];
    }
    return nil;
}

- (MediaLocator*) _findMediaLocatorForTag:(NSString*)tag 
{
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:mediaLocatorEntity];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"tag == %@", tag]];
    NSError* error = nil;
    NSArray* results = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    [fetchRequest release];
    if (!error && [results count]) {
        return [results objectAtIndex:0];
    }
    return nil;
}

- (NSString*) _frontCoverURLForFingerprint:(NSString*)fingerprint
{
    return [[NSURL URLWithString:[NSString stringWithFormat:@"/%@/FrontCover", fingerprint] relativeToURL:baseImageURL] absoluteString];
}

- (void) acceptConnection:(NSNotification*)notification 
{
    [[notification object] acceptConnectionInBackgroundAndNotify];

    NSFileHandle* connection = [[notification userInfo] objectForKey:NSFileHandleNotificationFileHandleItem];
    MessageProtocol* protocol = nil;
    @try {
        size_t sendBufferSize = 512 * 0x400;
        size_t receiveBufferSize = 512 * 0x400;
        int fd = [connection fileDescriptor];
        setsockopt(fd, SOL_SOCKET, SO_SNDBUF, (void*)&sendBufferSize, sizeof(sendBufferSize));
        setsockopt(fd, SOL_SOCKET, SO_RCVBUF, (void*)&receiveBufferSize, sizeof(receiveBufferSize));
        
        protocol = [MessageProtocol protocolWithDelegate:self fileHandleForReading:connection fileHandleForWriting:connection];
        
        NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
        [fetchRequest setEntity:discEntity];
        NSArray* results = [managedObjectContext executeFetchRequest:fetchRequest error:nil];
        if ([results count]) {
            NSMutableDictionary* adds = [NSMutableDictionary dictionary];
            NSMutableDictionary* updates = [NSMutableDictionary dictionary];
            for (Disc* disc in results) {
                NSMutableArray* urls = [NSMutableArray array];
                for (MediaLocator* mediaLocator in disc.allMediaLocators) {
                    [urls addObject:mediaLocator.tag];
                }
                [adds setObject:[NSDictionary dictionaryWithObjectsAndKeys:urls, @"urls", [self _frontCoverURLForFingerprint:disc.fingerprint], @"frontCoverURL", nil] forKey:disc.fingerprint];
                [updates setObject:disc.infoDictionary forKey:disc.fingerprint];
            }
            [protocol sendMessage:[NSDictionary dictionaryWithObjectsAndKeys:adds, @"add", updates, @"update", nil]];
        }
        [protocols addObject:protocol];
    } @catch (id exception) {
        [protocol close];
    }
}

- (NSMutableDictionary*) determineChangedKeysUsingDictionary:(NSMutableDictionary*)ad andDictionary:(NSMutableDictionary*)bd
{
    NSMutableDictionary* newKeys = nil;
    NSEnumerator* a = [[[ad allKeys] sortedArrayUsingSelector:@selector(compare:)] objectEnumerator];
    NSEnumerator* b = [[[bd allKeys] sortedArrayUsingSelector:@selector(compare:)] objectEnumerator];
    NSString* ak = [a nextObject], *bk = [b nextObject];
    id bv = [bd objectForKey:bk];
    while (bk && ak) {
        int v = [bk compare:ak];
        if (v > 0) {
            ak = [a nextObject];
        } else if (v < 0) {
            if (!newKeys) {
                newKeys = [NSMutableDictionary dictionary];
            }
            [newKeys setObject:[bd objectForKey:bk] forKey:bk];
            bk = [b nextObject];
            bv = [bd objectForKey:bk];
        } else if (v == 0) {
            if (![bv isEqual:[ad objectForKey:bk]]) {
                if (!newKeys) {
                    newKeys = [NSMutableDictionary dictionary];
                }
                [newKeys setObject:[bd objectForKey:bk] forKey:bk];
            }
            bk = [b nextObject];
            bv = [bd objectForKey:bk];
        }
    }
    if (bk) {
        if (!newKeys) {
            newKeys = [NSMutableDictionary dictionary];
        }
        do {
            [newKeys setObject:bv forKey:bk];
        } while ((bk = [b nextObject]) && (bv = [bd objectForKey:bk]));
    }
    return newKeys;
}

- (void) mergeInfoForDisc:(NSDictionary*)discInfo withMediaInfo:(NSDictionary*)mediaInfo newKeyPathsAndObjects:(NSMutableDictionary**)newKeyPathsAndObjects mergedInfoDictionary:(NSMutableDictionary**)mergedInfoDictionary 
{
    /*  Grab the relevant parts of the Disc Info
     */
    NSMutableDictionary* infoA = [NSMutableDictionary dictionaryWithDictionary:discInfo];
    NSMutableDictionary* movieA = [infoA objectForKey:@"movie"];
    if (!movieA) {
        [infoA setObject:movieA = [NSMutableDictionary dictionary] forKey:@"movie"];
    }
    NSMutableArray* synthesizedKeysA = [movieA objectForKey:@"synthesized-keys"];
    if (!synthesizedKeysA) {
        [movieA setObject:synthesizedKeysA = [NSMutableArray array] forKey:@"synthesized-keys"];
    }
    NSMutableArray* userKeysA = [NSMutableArray arrayWithArray:[movieA allKeys]];
    [userKeysA removeObjectsInArray:synthesizedKeysA];

    /*  Grab the relevant parts of the MediaFile Info
     */
    NSMutableDictionary* infoB = [NSMutableDictionary dictionaryWithDictionary:mediaInfo];
    NSMutableDictionary* movieB = [infoB objectForKey:@"movie"];
    if (!movieB) {
        [infoB setObject:movieB = [NSMutableDictionary dictionary] forKey:@"movie"];
    }
    NSMutableArray* synthesizedKeysB = [movieB objectForKey:@"synthesized-keys"];
    if (!synthesizedKeysB) {
        [movieB setObject:synthesizedKeysB = [NSMutableArray array] forKey:@"synthesized-keys"];
    }
    NSMutableArray* userKeysB = [NSMutableArray arrayWithArray:[movieB allKeys]];
    [userKeysB removeObjectsInArray:synthesizedKeysB];
        
    /*  Merge the user and synthesized keys arrays from both dictionaries (into
     *  userKeysB and synthesizedKeysB, respectively).
     */
    NSMutableSet* mergedSynthesizedKeys = [NSMutableSet setWithArray:synthesizedKeysA];
    NSMutableSet* mergedUserKeys = [NSMutableSet setWithArray:userKeysA];
    [mergedUserKeys addObjectsFromArray:userKeysB];
    [mergedSynthesizedKeys addObjectsFromArray:synthesizedKeysB];
    [mergedSynthesizedKeys minusSet:mergedUserKeys];
    /**/
    [userKeysB removeAllObjects];
    [userKeysB addObjectsFromArray:[mergedUserKeys allObjects]];
    [synthesizedKeysB removeAllObjects];
    [synthesizedKeysB addObjectsFromArray:[mergedSynthesizedKeys allObjects]];
    
    /*  Grab any second-level meta keys that aren't prefixed with an "_" and 
     *  merge them into the movieB dictionary as synthesized keys.
     */
    NSMutableDictionary* topLevelB = [infoB objectForKey:@"meta"];
    for (NSString* topLevelKeyB in topLevelB) {
        NSMutableDictionary* secondLevelB = [topLevelB objectForKey:topLevelKeyB];
        for (NSString* secondLevelKeyB in secondLevelB) {
            if (![secondLevelKeyB hasPrefix:@"_"] && ![mergedUserKeys containsObject:secondLevelKeyB]) {
                id object = [secondLevelB objectForKey:secondLevelKeyB];
                [movieB setObject:object forKey:secondLevelKeyB];
                if (![synthesizedKeysB containsObject:secondLevelKeyB]) {
                    [synthesizedKeysB addObject:secondLevelKeyB];
                }
            }
        }
    }
    [synthesizedKeysB sortUsingSelector:@selector(compare:)];

    /*  Flatten infoA and infoB and merge them into a new dictionary, and assign
     *  that to the disc.infoDictionary property.
     */
    NSMutableDictionary* flattenedInfoA = [infoA flattenToKeyPathsAndObjects];
    NSMutableDictionary* flattenedInfoB = [infoB flattenToKeyPathsAndObjects];
    NSMutableDictionary* changedKeys = [self determineChangedKeysUsingDictionary:flattenedInfoA andDictionary:flattenedInfoB];
    if ([changedKeys count]) {
        if (mergedInfoDictionary) {
            [flattenedInfoA addEntriesFromDictionary:changedKeys];
            *mergedInfoDictionary = [NSDictionary dictionaryWithExpandedKeyPathsAndObjects:flattenedInfoA];
        }
        if (newKeyPathsAndObjects) {
            *newKeyPathsAndObjects = changedKeys;
        }
    }
}

- (void) sendMessage:(NSDictionary*)message
{
#ifdef DEBUG
    NSLog(@"%@", [NSDictionary dictionaryWithJSON:[NSString stringWithObjectAsJSON:message]]);
#endif
    for (MessageProtocol* protocol in protocols) {
        @try {
            [protocol sendMessage:message];
        } @catch (id exception) {
            [protocol close];
            [protocols removeObject:protocol];
        }
    }
}


#pragma mark HTTPServerDelegate

- (void) processURL:(NSURL*)url connection:(HTTPConnection*)connection;
{
    NSArray* parts = [[url path] componentsSeparatedByString:@"/"];
    NSString* fingerprint = nil;
    if ([parts count] == 3 && [@"FrontCover" isEqualToString:[parts objectAtIndex:2]] && [fingerprint = [parts objectAtIndex:1] length] == 36) {
        Disc* disc = nil;
        @synchronized (managedObjectContext) {
            disc = [self _findDiscByFingerprint:fingerprint];
        }
        if (disc) {
            NSData* frontCover = nil;
            for (MediaLocator* mediaLocator in disc.allMediaLocators) {
                MediaFile* mediaFile = [mediaFileByTag objectForKey:mediaLocator.tag];
                frontCover = mediaFile.frontCover;
                if (frontCover) {
                    break;
                }
            }
            if (frontCover) {
                [connection replyWithData:frontCover MIMEType:@"image/png"];
                return;
            }
        }
    }
    [connection replyWithStatusCode:404 message:nil];
}


#pragma mark MediaSourceDelegate

- (void) mediaFileSource:(id<MediaFileSource>)mediaSource didAddMedia:(NSArray*)arrayOfMedia
{
    @synchronized (managedObjectContext) {
        NSMutableDictionary* addsByFingerprint = [NSMutableDictionary dictionary];
        NSMutableDictionary* updatesByFingerprint = [NSMutableDictionary dictionary];

        for (MediaFile* media in arrayOfMedia) {
            struct statfs64 sb;
            bzero(&sb, sizeof(sb));
            int error = statfs64([media.pathToFile fileSystemRepresentation], &sb);
            if (error) {
                NSLog(@"Unable to statfs (%@): %s", media.pathToFile, strerror(error));
                continue;
            }
            
            /*  Search for the MediaLocator using the file system ID at the
             *  given relative path.  If we don't find a record of it, go
             *  ahead and setup a new one.
             */
            NSString* fileSystemID = [NSString stringWithFormat:@"%08x%08x", sb.f_fsid.val[1], sb.f_fsid.val[0]];
            NSString* relativePath = [media.pathToFile substringFromIndex:strlen(sb.f_mntonname)];
            MediaLocator* mediaLocator = [self _findMediaLocatorForFileSystemID:fileSystemID relativePath:relativePath];
            if (!mediaLocator) {
                mediaLocator = [[MediaLocator alloc] initWithEntity:mediaLocatorEntity insertIntoManagedObjectContext:managedObjectContext];
                mediaLocator.fileSystemID = fileSystemID;
                mediaLocator.relativePath = relativePath;
                mediaLocator.tag = [NSString stringWithUUID];
            }
            media.tag = mediaLocator.tag;
            [mediaFileByTag setObject:media forKey:media.tag];
            
            NSString* mediaFingerprint = [media fingerprint];
            if (mediaFingerprint) {
                /*  Attempt to add this disc to a movie using the new fingerprint.
                 *  If a movie doesn't exist, create one and treat it like an add,
                 *  otherwise, we can consider this a normal update to an existing
                 *  movie.
                 */
                Disc* disc = [self _findDiscByFingerprint:mediaFingerprint];
                if (!disc) {
                    disc = [[Disc alloc] initWithEntity:discEntity insertIntoManagedObjectContext:managedObjectContext];
                    disc.fingerprint = mediaFingerprint;
                    disc.infoDictionary = [infoDictionariesByFingerprint objectForKey:mediaFingerprint];
                    if (![disc.infoDictionary valueForKeyPath:@"meta.discident"]) {
                        [DiscIdentQuery queryWithFingerprint:mediaFingerprint delegate:self userInfo:[disc retain] startImmediately:YES];
                    }
                }
                mediaLocator.disc = disc;
                mediaLocator.lastSeen = [NSDate date];
                mediaLocator.isAvailable = (id)kCFBooleanTrue;
                
                /*
                 */
                NSMutableDictionary* entry = [addsByFingerprint objectForKey:mediaFingerprint];
                if (!entry) {
                    [addsByFingerprint setObject:
                        entry = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                            [NSMutableArray arrayWithObject:media.tag],
                            @"urls",
                            nil
                        ]
                        forKey:
                            mediaFingerprint
                    ];
                } else {
                    [[entry objectForKey:@"urls"] addObject:media.tag];
                }
                [entry setObject:[self _frontCoverURLForFingerprint:media.fingerprint] forKey:@"frontCoverURL"];
                
                /*  Read in the info dictionary, and merge it with any that we've
                 *  already loaded.
                 */
                NSMutableDictionary* newKeyPathsAndObjects = nil;
                NSMutableDictionary* infoDictionary = nil;
                [self mergeInfoForDisc:[infoDictionariesByFingerprint objectForKey:mediaFingerprint] withMediaInfo:media.infoDictionary newKeyPathsAndObjects:&newKeyPathsAndObjects mergedInfoDictionary:&infoDictionary];
                if ([newKeyPathsAndObjects count]) {
                    NSMutableDictionary* entry = [updatesByFingerprint objectForKey:mediaFingerprint];
                    if (!entry) {
                        [updatesByFingerprint setObject:[NSDictionary dictionaryWithExpandedKeyPathsAndObjects:newKeyPathsAndObjects] forKey:mediaFingerprint];
                    } else {
                        NSMutableDictionary* flattenedInfoForFingerprint = [entry flattenToKeyPathsAndObjects];
                        [flattenedInfoForFingerprint addEntriesFromDictionary:newKeyPathsAndObjects];
                        [updatesByFingerprint setObject:[NSDictionary dictionaryWithExpandedKeyPathsAndObjects:flattenedInfoForFingerprint] forKey:mediaFingerprint];
                    }

                    [infoDictionariesByFingerprint setObject:infoDictionary forKey:mediaFingerprint];
                    disc.infoDictionary = infoDictionary;
                }
            } else {
                static NSString* pathToMDImport = @"/usr/bin/mdimport";
                [NSTask launchedTaskWithLaunchPath:pathToMDImport arguments:[NSArray arrayWithObjects:pathToMDImport, [media pathToFile], nil]];
            }
        }
        
        [managedObjectContext save:nil];

        /*  Build and send the message.
         */
        if ([addsByFingerprint count] || [updatesByFingerprint count]) {
            NSMutableDictionary* message = [NSMutableDictionary dictionary];
            if ([addsByFingerprint count]) {
                [message setObject:addsByFingerprint forKey:@"add"];
            }
            if ([updatesByFingerprint count]) {
                [message setObject:updatesByFingerprint forKey:@"update"];
            }
            [self sendMessage:message];
        }
    }
}

- (void) mediaFileSource:(id<MediaFileSource>)mediaSource didUpdateMedia:(NSArray*)arrayOfMedia
{
    @synchronized (managedObjectContext) {
        NSMutableDictionary* addsByFingerprint = [NSMutableDictionary dictionary];
        NSMutableDictionary* updatesByFingerprint = [NSMutableDictionary dictionary];
        NSMutableDictionary* deletesByFingerprint = [NSMutableDictionary dictionary];
        for (MediaFile* media in arrayOfMedia) {
            MediaLocator* mediaLocator = [self _findMediaLocatorForTag:media.tag];
            if (!mediaLocator) {
                NSLog(@"Unable to find MedaLocator (%@)", media.tag);
                continue;
            }
            
            struct statfs64 sb;
            bzero(&sb, sizeof(sb));
            int error = statfs64([media.pathToFile fileSystemRepresentation], &sb);
            if (error) {
                NSLog(@"Unable to statfs (%@): %s", media.pathToFile, strerror(error));
                continue;
            }
            
            NSString* relativePath = [media.pathToFile substringFromIndex:strlen(sb.f_mntonname)];
            NSString* mediaFingerprint = media.fingerprint;
            NSString* discFingerprint = mediaLocator.disc.fingerprint;
            if (mediaFingerprint && ![mediaFingerprint isEqualToString:discFingerprint] || ![mediaLocator.relativePath isEqualToString:relativePath]) {
                /*  Remove this disc from the movie it used to match up with.  If
                 *  that causes there to be no more discs for that movie, then 
                 *  we'll need to delete it.
                 */
                if (discFingerprint) {
                    Disc* disc = mediaLocator.disc;
                    mediaLocator.disc = nil;
                    if (0 == [disc.allMediaLocators count]) {
                        [managedObjectContext deleteObject:disc];
                    }
                    [managedObjectContext deleteObject:mediaLocator];

                    NSMutableDictionary* entry = [deletesByFingerprint objectForKey:discFingerprint];
                    if (!entry) {
                        [deletesByFingerprint setObject:
                            entry = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                [NSMutableArray arrayWithObject:media.tag],
                                @"urls",
                                nil
                            ]
                            forKey:
                                discFingerprint
                        ];
                    } else {
                        [[entry objectForKey:@"urls"] addObject:media.tag];
                    }
                }

                [media reload];

                /*  Attempt to add this disc to a movie using the new fingerprint.
                 *  If a movie doesn't exist, create one and treat it like an add,
                 *  otherwise, we can consider this a normal update to an existing
                 *  movie.
                 */
                mediaLocator.relativePath = relativePath;
                mediaLocator.lastSeen = [NSDate date];
                mediaLocator.isAvailable = (id)kCFBooleanTrue;
                
                if (mediaFingerprint) {
                    Disc* disc = [self _findDiscByFingerprint:mediaFingerprint];
                    if (!disc) {
                        disc = [[Disc alloc] initWithEntity:discEntity insertIntoManagedObjectContext:managedObjectContext];
                        disc.fingerprint = mediaFingerprint;
                    }
                    mediaLocator.disc = disc;
                
                    NSMutableDictionary* entry = [addsByFingerprint objectForKey:mediaFingerprint];
                    if (!entry) {
                        [addsByFingerprint setObject:
                            entry = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                [NSMutableArray arrayWithObject:media.tag],
                                @"urls",
                                nil
                            ]
                            forKey:
                                mediaFingerprint
                        ];
                    } else {
                        [[entry objectForKey:@"urls"] addObject:media.tag];
                    }
                    [entry setObject:[self _frontCoverURLForFingerprint:media.fingerprint] forKey:@"frontCoverURL"];
                }

                /*  Read in the info dictionary, and merge it with any that we've
                 *  already loaded.
                 */
                NSMutableDictionary* newKeyPathsAndObjects = nil;
                NSMutableDictionary* infoDictionary = nil;
                [self mergeInfoForDisc:[infoDictionariesByFingerprint objectForKey:mediaFingerprint] withMediaInfo:media.infoDictionary newKeyPathsAndObjects:&newKeyPathsAndObjects mergedInfoDictionary:&infoDictionary];
                if ([newKeyPathsAndObjects count]) {
                    NSMutableDictionary* entry = [updatesByFingerprint objectForKey:mediaFingerprint];
                    if (!entry) {
                        [updatesByFingerprint setObject:[NSDictionary dictionaryWithExpandedKeyPathsAndObjects:newKeyPathsAndObjects] forKey:mediaFingerprint];
                    } else {
                        NSMutableDictionary* flattenedInfoForFingerprint = [entry flattenToKeyPathsAndObjects];
                        [flattenedInfoForFingerprint addEntriesFromDictionary:newKeyPathsAndObjects];
                        [updatesByFingerprint setObject:[NSDictionary dictionaryWithExpandedKeyPathsAndObjects:flattenedInfoForFingerprint] forKey:mediaFingerprint];
                    }
                    
                    [infoDictionariesByFingerprint setObject:infoDictionary forKey:mediaFingerprint];
                    media.disc.infoDictionary = infoDictionary;
                }
            }
        }

        [managedObjectContext save:nil];

        /*  Build and send the message.
         */
        if ([addsByFingerprint count] || [updatesByFingerprint count] || [deletesByFingerprint count]) {
            NSMutableDictionary* message = [NSMutableDictionary dictionary];
            if ([addsByFingerprint count]) {
                [message setObject:addsByFingerprint forKey:@"add"];
            }
            if ([updatesByFingerprint count]) {
                [message setObject:updatesByFingerprint forKey:@"update"];
            }
            if ([deletesByFingerprint count]) {
                [message setObject:deletesByFingerprint forKey:@"delete"];
            }
            [self sendMessage:message];
        }
    }
}

- (void) mediaFileSource:(id<MediaFileSource>)mediaSource didRemoveMedia:(NSArray*)arrayOfMedia
{
    @synchronized (managedObjectContext) {
        NSMutableDictionary* deletesByFingerprint = [NSMutableDictionary dictionary];
        for (MediaFile* media in arrayOfMedia) {
            [mediaFileByTag removeObjectForKey:media.tag];

            NSString* fingerprint = nil;
            MediaLocator* mediaLocator = [self _findMediaLocatorForTag:media.tag];
            if (mediaLocator) {
                Disc* disc = mediaLocator.disc;
                fingerprint = disc.fingerprint;
                mediaLocator.disc = nil;
                if (0 == [disc.allMediaLocators count]) {
                    [managedObjectContext deleteObject:disc];
                }
                [managedObjectContext deleteObject:mediaLocator];
            }
                
            NSMutableDictionary* entry = [deletesByFingerprint objectForKey:fingerprint];
            if (!entry) {
                [deletesByFingerprint setObject:
                    entry = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                        [NSMutableArray arrayWithObject:media.tag],
                        @"urls",
                        nil
                    ]
                    forKey:
                        fingerprint
                ];
            } else {
                [[entry objectForKey:@"urls"] addObject:media.tag];
            }
        }

        [managedObjectContext save:nil];

        /*  Build and send the message.
         */
        if ([deletesByFingerprint count]) {
            NSMutableDictionary* message = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                deletesByFingerprint,
                @"delete",
                nil
            ];
            [self sendMessage:message];
        }
    }
}


#pragma mark NSNetServiceDelegate

- (void) netService:(NSNetService*)netService didNotPublish:(NSDictionary*)errorInfo
{
    NSLog(@"Unable to publish: %@", errorInfo);
}

- (void) netServiceDidPublish:(NSNetService*)netService
{
    NSLog(@"Published.");
}


#pragma mark MessageProtocolDelegate

- (void) protocol:(MessageProtocol*)protocol didReceiveMessage:(NSDictionary*)messageDict
{
    /* TODO: Implement me */
}

- (void) protocolDidClose:(MessageProtocol*)protocol
{
    [protocols removeObject:protocol];
}


#pragma mark DiscIdentQueryDelegate

- (void) discIdentQuery:(DiscIdentQuery*)query didFailWithError:(NSError*)error userInfo:(void*)userInfo
{
    Disc* disc = (Disc*)userInfo;
    [disc release];
}

- (void) discIdentQuery:(DiscIdentQuery*)query didReceiveResponse:(NSDictionary*)response userInfo:(void*)userInfo
{
    Disc* disc = (Disc*)userInfo;
    NSMutableDictionary* newKeyPathsAndObjects = nil;
    NSMutableDictionary* infoDictionary = nil;
    [self mergeInfoForDisc:[infoDictionariesByFingerprint objectForKey:disc.fingerprint] withMediaInfo:[NSDictionary dictionaryWithObject:[NSDictionary dictionaryWithObject:response forKey:@"discident"] forKey:@"meta"] newKeyPathsAndObjects:&newKeyPathsAndObjects mergedInfoDictionary:&infoDictionary];
    if ([newKeyPathsAndObjects count]) {
        [infoDictionariesByFingerprint setObject:infoDictionary forKey:disc.fingerprint];
        disc.infoDictionary = infoDictionary;
        [self sendMessage:[NSDictionary dictionaryWithObject:[NSDictionary dictionaryWithObject:[NSDictionary dictionaryWithExpandedKeyPathsAndObjects:newKeyPathsAndObjects] forKey:disc.fingerprint] forKey:@"update"]];
    }
    
    NSString* gtin = [newKeyPathsAndObjects objectForKey:@"meta.discident.gtin"];
    if ([gtin characterAtIndex:0] == '0') {
        [AmazonQuery amazonQueryWithAccessKey:kAmazonAccessKey ean:[gtin substringFromIndex:1] delegate:self userInfo:disc startImmediately:YES];
    }

    [disc release];
}


#pragma mark AmazonQueryDelegate

- (void) amazonQuery:(AmazonQuery*)query didReceiveResponse:(NSDictionary*)response userInfo:(id)userInfo
{
    Disc* disc = (Disc*)userInfo;
    NSMutableDictionary* newKeyPathsAndObjects = nil;
    NSMutableDictionary* infoDictionary = nil;
    [self mergeInfoForDisc:[infoDictionariesByFingerprint objectForKey:disc.fingerprint] withMediaInfo:[NSDictionary dictionaryWithObject:[NSDictionary dictionaryWithObject:response forKey:@"amazon"] forKey:@"meta"] newKeyPathsAndObjects:&newKeyPathsAndObjects mergedInfoDictionary:&infoDictionary];
    if ([newKeyPathsAndObjects count]) {
        [infoDictionariesByFingerprint setObject:infoDictionary forKey:disc.fingerprint];
        disc.infoDictionary = infoDictionary;
        [self sendMessage:[NSDictionary dictionaryWithObject:[NSDictionary dictionaryWithObject:[NSDictionary dictionaryWithExpandedKeyPathsAndObjects:newKeyPathsAndObjects] forKey:disc.fingerprint] forKey:@"update"]];
    }
    
    NSString* coverImageURL = [newKeyPathsAndObjects objectForKey:@"meta.amazon._coverImageURL"];
    if (coverImageURL) @try {
        [ImageQuery imageQueryWithURL:[NSURL URLWithString:coverImageURL] delegate:self userInfo:disc startImmediately:YES];
    } @catch (id exception) {
        /* Ignored */
    }

    [disc release];
}


#pragma mark CoverArtQueryDelegate

- (void) imageQuery:(ImageQuery*)query didReceiveImage:(NSImage*)response userInfo:(id)userInfo
{
    Disc* disc = (Disc*)userInfo;

    /*  TODO: Process/Crop image to appropriate dimensions.  */
    
//    for (NSString* url in disc.mediaURLs) {
//        [[mediaByURL objectForKey:url] setFrontCover:[response PNGRepresentation]];
//    }
}

@end
