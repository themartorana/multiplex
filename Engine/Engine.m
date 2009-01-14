#import "Engine.h"
#import "Model/MediaLocator.h"

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
- (NSString*) _frontCoverURLForTag:(NSString*)fingeprint;

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
            NSURL* modelURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Engine" ofType:@"mom"]];
            managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
            persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:managedObjectModel];
            [persistentStoreCoordinator addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:nil options:nil error:nil];
            managedObjectContext = [[NSManagedObjectContext alloc] init];
            [managedObjectContext setPersistentStoreCoordinator:persistentStoreCoordinator];
            
            NSDictionary* entitiesByName = [managedObjectModel entitiesByName];
            mediaLocatorEntity = [entitiesByName objectForKey:@"MediaLocator"];
            
#if 0
            NSDate* now = [NSDate date];
            NSDate* thirtyDaysAgo = [NSDate dateWithTimeIntervalSinceNow:-(30 * 24 * 60 * 60)];
            NSFileManager* fileManager = [NSFileManager defaultManager];
            NSFetchRequest* fetchRequest = [[[NSFetchRequest alloc] init] autorelease];
            [fetchRequest setEntity:mediaLocatorEntity];
            for (MediaLocator* mediaLocator in [managedObjectContext executeFetchRequest:fetchRequest error:nil]) {
                BOOL isAvailable = [fileManager fileExistsAtPath:mediaLocator.pathToFile];
                if (isAvailable) {
                    mediaLocator.lastSeen = now;
                    mediaLocator.isAvailable = (id)kCFBooleanTrue;
                } else {
                    if (thirtyDaysAgo == [mediaLocator.lastSeen laterDate:thirtyDaysAgo]) {
                        [managedObjectContext deleteObject:mediaLocator];
                    } else {
                        mediaLocator.isAvailable = (id)kCFBooleanFalse;
                    }
                }
            }
#endif
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
            baseWebServerURL = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"http://%@.local:%d/", SCDynamicStoreCopyLocalHostName(NULL,NULL), ntohs(psin6->sin6_port)]];
            NSLog(@"%@", baseWebServerURL);
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
    [netService publishWithOptions:0];
}

- (MediaLocator*) _findMediaLocatorByPathToFile:(NSString*)pathToFile fingerprint:(NSString*)fingeprint 
{
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:mediaLocatorEntity];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"pathToFile == %@ and fingerprint == %@", pathToFile, fingeprint]];
    NSError* error = nil;
    NSArray* results = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    [fetchRequest release];
    if (!error && [results count]) {
        return [results objectAtIndex:0];
    }
    return nil;
}

- (MediaLocator*) _findMediaLocatorByTag:(NSString*)tag 
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

- (NSString*) _infoURLForTag:(NSString*)tag
{
    return [[NSURL URLWithString:[NSString stringWithFormat:@"/%@/Info.json", tag] relativeToURL:baseWebServerURL] absoluteString];
}

- (NSString*) _frontCoverURLForTag:(NSString*)tag
{
    return [[NSURL URLWithString:[NSString stringWithFormat:@"/%@/FrontCover", tag] relativeToURL:baseWebServerURL] absoluteString];
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

        NSMutableDictionary* adds = nil;
        @synchronized (managedObjectContext) {
            NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
            [fetchRequest setEntity:mediaLocatorEntity];
            [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"isAvailable == YES"]];
            NSArray* results = [managedObjectContext executeFetchRequest:fetchRequest error:nil];
            if ([results count]) {
                adds = [NSMutableDictionary dictionary];
                for (MediaLocator* mediaLocator in results) {
                    NSMutableDictionary* add = [NSMutableDictionary dictionaryWithObjectsAndKeys:mediaLocator.isAvailable, @"isAvailable", mediaLocator.type, @"type", mediaLocator.pathToFile, @"pathToFile", mediaLocator.fingerprint, @"fingerprint", nil];
                    if ([mediaLocator.hasInfo boolValue]) {
                        [add setObject:[self _infoURLForTag:mediaLocator.tag] forKey:@"infoURL"];
                    }
                    if ([mediaLocator.hasFrontCover boolValue]) {
                        [add setObject:[self _frontCoverURLForTag:mediaLocator.tag] forKey:@"frontCoverURL"];    
                    }
                    [adds setObject:add forKey:mediaLocator.tag];
                }
            }
        }
        if (adds) {  
            [protocol sendMessage:[NSDictionary dictionaryWithObjectsAndKeys:adds, @"add", nil]];
        }
        [protocol sendMessage:[NSDictionary dictionaryWithObjectsAndKeys:(id)kCFBooleanTrue, @"finished", nil]];
        [protocols addObject:protocol];
    } @catch (id exception) {
        [protocol close];
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
    NSString* tag = nil;
    if ([parts count] == 3 && [@"FrontCover" isEqualToString:[parts objectAtIndex:2]] && [tag = [parts objectAtIndex:1] length] == 36) {
        MediaFile* mediaFile = [mediaFileByTag objectForKey:tag];
        NSData* frontCover = mediaFile.frontCover;
        if (frontCover) {
            [connection replyWithData:frontCover MIMEType:@"image/png"];
            return;
        }
    } else if ([parts count] == 3 && [@"Info.json" isEqualToString:[parts objectAtIndex:2]] && [tag = [parts objectAtIndex:1] length] == 36) {
        MediaFile* mediaFile = [mediaFileByTag objectForKey:tag];
        NSData* infoJSON = [NSData dataWithObjectAsJSON:mediaFile.infoDictionary];
        if (infoJSON) {
            [connection replyWithData:infoJSON MIMEType:@"text/json"];
            return;
        }
    }
        
    [connection replyWithStatusCode:404 message:nil];
}


#pragma mark MediaSourceDelegate

- (void) mediaFileSource:(id<MediaFileSource>)mediaSource didAddMedia:(NSArray*)arrayOfMedia
{
    @synchronized (managedObjectContext) {
        NSMutableDictionary* adds = [NSMutableDictionary dictionary];
        NSMutableDictionary* updates = [NSMutableDictionary dictionary];
        NSDate* now = [NSDate date];
        
        for (MediaFile* mediaFile in arrayOfMedia) {            
            NSMutableDictionary* addOrUpdate = nil;
            MediaLocator* mediaLocator = [self _findMediaLocatorByPathToFile:mediaFile.pathToFile fingerprint:mediaFile.fingerprint];
            if (mediaLocator) {
                if ([mediaLocator.isAvailable boolValue]) {
                    addOrUpdate = updates;
                } else {
                    addOrUpdate = adds;
                }
            } else {
                addOrUpdate = adds;
                mediaLocator = [[[MediaLocator alloc] initWithEntity:mediaLocatorEntity insertIntoManagedObjectContext:managedObjectContext] autorelease];
                mediaLocator.tag = [NSString stringWithUUID];
            }
            mediaLocator.lastSeen = now;
            mediaLocator.pathToFile = mediaFile.pathToFile;
            mediaLocator.fingerprint = mediaFile.fingerprint;
            mediaLocator.type = mediaFile.type;
            
            mediaFile.tag = mediaLocator.tag;
            [mediaFileByTag setObject:mediaFile forKey:mediaFile.tag];

            NSAssert(addOrUpdate, @"wtf?");
            if (mediaFile.fingerprint) {
                mediaLocator.isAvailable = (id)kCFBooleanTrue;
                NSMutableDictionary* entry = [NSMutableDictionary dictionaryWithObjectsAndKeys:mediaLocator.isAvailable, @"isAvailable", mediaLocator.type, @"type", mediaLocator.pathToFile, @"pathToFile", mediaLocator.fingerprint, @"fingerprint", nil];
                if (mediaFile.infoDictionary) {
                    mediaLocator.hasInfo = (id)kCFBooleanTrue;
                    [entry setObject:[self _infoURLForTag:mediaLocator.tag] forKey:@"infoURL"];
                }
                if (mediaFile.frontCover) {
                    mediaLocator.hasFrontCover = (id)kCFBooleanTrue;
                    [entry setObject:[self _frontCoverURLForTag:mediaLocator.tag] forKey:@"frontCoverURL"];    
                }
                [addOrUpdate setObject:entry forKey:mediaLocator.tag];
            } else {
                mediaLocator.isAvailable = (id)kCFBooleanFalse;
                [NSTask launchedTaskWithLaunchPath:@"/usr/bin/mdimport" arguments:[NSArray arrayWithObjects:@"mdimport", mediaFile.pathToFile, nil]];
            }
        }
        
        NSError* error = nil;
        [managedObjectContext save:&error];
        if (error) {
            NSLog(@"%s - %@ - %@", __PRETTY_FUNCTION__, error, error.userInfo);
        }

        /*  Build and send the message.
         */
        if ([adds count] || [updates count]) {
            NSMutableDictionary* message = [NSMutableDictionary dictionary];
            if ([adds count]) {
                [message setObject:adds forKey:@"add"];
            }
            if ([updates count]) {
                [message setObject:updates forKey:@"update"];
            }
            [self sendMessage:message];
        }
    }
}

- (void) mediaFileSource:(id<MediaFileSource>)mediaSource didUpdateMedia:(NSArray*)arrayOfMedia
{
    @synchronized (managedObjectContext) {
        NSMutableDictionary* adds = [NSMutableDictionary dictionary];
        NSMutableDictionary* updates = [NSMutableDictionary dictionary];
        NSMutableArray* deletes = [NSMutableArray array];
        NSMutableDictionary* change = [NSMutableDictionary dictionary];

        for (MediaFile* mediaFile in arrayOfMedia) {
            MediaLocator* mediaLocator = [self _findMediaLocatorByTag:mediaFile.tag];
            NSAssert(mediaLocator, @"wtf?");
            
            [mediaFile reload];

            if (nil == mediaFile.fingerprint) {
                mediaLocator.isAvailable = (id)kCFBooleanFalse;
                [deletes addObject:mediaFile.tag];
            } else {
                if ([mediaLocator.isAvailable boolValue]) {
                    if (![mediaLocator.type isEqualToString:mediaFile.type]) {
                        mediaLocator.type = mediaFile.type;
                        [change setObject:mediaFile.type forKey:@"type"];
                    }
                    
                    if (![mediaLocator.pathToFile isEqualToString:mediaFile.pathToFile]) {
                        mediaLocator.pathToFile = mediaFile.pathToFile;
                        [change setObject:mediaFile.pathToFile forKey:@"pathToFile"];
                    }
                    
                    if (![mediaLocator.fingerprint isEqualToString:mediaFile.fingerprint]) {
                        mediaLocator.fingerprint = mediaFile.fingerprint;
                        [change setObject:mediaFile.fingerprint forKey:@"fingerprint"];
                    }
                    
                    NSDictionary* infoDictionary = mediaFile.infoDictionary;
                    if (![mediaLocator.hasInfo boolValue] && infoDictionary) {
                        mediaLocator.hasInfo = (id)kCFBooleanTrue;
                        [change setObject:[self _infoURLForTag:mediaLocator.tag] forKey:@"infoURL"];
                    } else if ([mediaLocator.hasInfo boolValue] && !infoDictionary) {
                        mediaLocator.hasInfo = (id)kCFBooleanFalse;
                        [change setObject:(id)kCFNull forKey:@"infoURL"];
                    }
                    
                    NSData* frontCover = mediaFile.frontCover;
                    if (![mediaLocator.hasFrontCover boolValue] && frontCover) {
                        mediaLocator.hasFrontCover = (id)kCFBooleanTrue;
                        [change setObject:[self _frontCoverURLForTag:mediaLocator.tag] forKey:@"frontCoverURL"];    
                    } else if ([mediaLocator.hasFrontCover boolValue] && !frontCover) {
                        mediaLocator.hasFrontCover = (id)kCFBooleanFalse;
                        [change setObject:(id)kCFNull forKey:@"frontCoverURL"];
                    }

                    if ([change count]) {
                        [updates setObject:change forKey:mediaFile.tag];
                        change = [NSMutableDictionary dictionary];
                    }
                } else {
                    mediaLocator.isAvailable = (id)kCFBooleanTrue;
                    mediaLocator.fingerprint = mediaFile.fingerprint;
                    
                    [change setObject:mediaLocator.isAvailable forKey:@"isAvailable"];
                    [change setObject:mediaLocator.type forKey:@"type"];
                    [change setObject:mediaLocator.pathToFile forKey:@"pathToFile"];
                    [change setObject:mediaFile.fingerprint forKey:@"fingerprint"];
                    if (mediaFile.infoDictionary) {
                        mediaLocator.hasInfo = (id)kCFBooleanTrue;
                        [change setObject:[self _infoURLForTag:mediaLocator.tag] forKey:@"infoURL"];
                    }
                    if (mediaFile.frontCover) {
                        mediaLocator.hasFrontCover = (id)kCFBooleanTrue;
                        [change setObject:[self _frontCoverURLForTag:mediaLocator.tag] forKey:@"frontCoverURL"];    
                    }
                    
                    [adds setObject:change forKey:mediaFile.tag];
                    change = [NSMutableDictionary dictionary];
                }
            }
        }

        NSError* error = nil;
        [managedObjectContext save:&error];
        if (error) {
            NSLog(@"%s - %@ - %@", __PRETTY_FUNCTION__, error, error.userInfo);
        }
        
        /*  Build and send the message.
         */
        if ([adds count] || [updates count] || [deletes count]) {
            NSMutableDictionary* message = [NSMutableDictionary dictionary];
            if ([adds count]) {
                [message setObject:adds forKey:@"add"];
            }
            if ([updates count]) {
                [message setObject:updates forKey:@"update"];
            }
            if ([deletes count]) {
                [message setObject:deletes forKey:@"delete"];
            }
            [self sendMessage:message];
        }
    }
}

- (void) mediaFileSource:(id<MediaFileSource>)mediaSource didRemoveMedia:(NSArray*)arrayOfMedia
{
    @synchronized (managedObjectContext) {
        NSMutableArray* deletes = [NSMutableArray array];
        for (MediaFile* media in arrayOfMedia) {
            [mediaFileByTag removeObjectForKey:media.tag];
            
            MediaLocator* mediaLocator = [self _findMediaLocatorByTag:media.tag];
            NSAssert(mediaLocator, @"wtf?");
            
            mediaLocator.isAvailable = (id)kCFBooleanFalse;

            [deletes addObject:mediaLocator.tag];
        }

        NSError* error = nil;
        [managedObjectContext save:&error];
        if (error) {
            NSLog(@"%s - %@ - %@", __PRETTY_FUNCTION__, error, error.userInfo);
        }

        /*  Build and send the message.
         */
        if ([deletes count]) {
            NSMutableDictionary* message = [NSMutableDictionary dictionary];
            [message setObject:deletes forKey:@"delete"];
            [self sendMessage:message];
        }
    }
}

- (void) mediaFileSource:(id<MediaFileSource>)mediaSource didFinishQuery:(BOOL)didFinish
{
    if (didFinish) {
        NSMutableDictionary* message = [NSMutableDictionary dictionary];
        [message setObject:[NSNumber numberWithBool:YES] forKey:@"finished"];
        [self sendMessage:message];
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

@end
