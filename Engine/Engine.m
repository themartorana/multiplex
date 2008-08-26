#import "Engine.h"
#import "Disc.h"
#import "Movie.h"
#import "DVDMediaSource.h"
#import "PhysicalMediaSource.h"
#import "JSONKit/JSONKit.h"
#import "DiscIdent.h"
#import "LibraryComProtocol.h"
#import "NSString+DiscIdent.h"

@implementation Engine

- (id) init
{
    if (self = [super init]) {
        moviesByFingerprint = [[NSMutableDictionary alloc] init];
        infoDictionariesByFingerprint = [[NSMutableDictionary alloc] init];
        
        // Set up the protocol
        protocol = [[LibraryComProtocol alloc] init];
        [protocol setFileHandleForReading:[NSFileHandle fileHandleWithStandardInput]];
        [protocol setFileHandleForWriting:[NSFileHandle fileHandleWithStandardOutput]];
        [protocol setDelegate:self];
    }
    return self;
}

- (void) dealloc
{    
    [protocol release];
    [moviesByFingerprint release];
    [infoDictionariesByFingerprint release];
    [super dealloc];
}

- (void) run
{
    /*  Register our media sources.  Later, this can be done more "plugin" 
     *  style.
     */
    NSArray* mediaSources = [NSArray arrayWithObjects:
        [[DVDMediaSource alloc] init],
        [[PhysicalMediaSource alloc] init],
        nil
    ];

    /*  Set ourselves as the media source's delegate, and then start it up.
     */
    for (id<MediaSource> mediaSource in mediaSources) {
        [mediaSource setDelegate:self];
        [mediaSource start];
    }

    /*  Process our message loop unil we're told to stop.
     */
    [super run];

    /*  Shutdown all of our media sources.
     */
    for (id<MediaSource> mediaSource in mediaSources) {
        [mediaSource stop];
    }
}

- (NSMutableDictionary*) infoDictionaryForItem:(Disc*)item  
{
    /*  Attempt to load the Info.json from the filesystem.  If this fails,
     *  we create a new, empty dictionary containing just the fingerprint.
     */
    NSMutableDictionary* info = nil;
    NSString* pathToJSONFile = [[item pathToFile] stringByAppendingPathComponent:@"_Info.json"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:pathToJSONFile]) {
        info = [NSDictionary dictionaryWithJSON:[NSString stringWithContentsOfFile:pathToJSONFile]];
    }
    if (!info) {
        info = [NSMutableDictionary dictionaryWithObject:[item fingerprint] forKey:@"com_discident_fingerprint"];
    } else if (![info objectForKey:@"com_discident_fingerprint"]) {
        [info setObject:[item fingerprint] forKey:@"com_discident_fingerprint"];
    }

    /*  All items should have a title, even if it's just one that's been
     *  derived from the (possibly crappy) name in the filesystem.
     */
    if (![info objectForKey:@"title"]) {
        NSString* title = [[[[item pathToFile] lastPathComponent] stringByDeletingPathExtension] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]];
        if (!title || ![title length]) {
            title = @"Untitled Movie";
        }
        [info setObject:title forKey:@"title"];
    }

    /*  Every item has an URL.
     */
    [info setObject:[[NSURL fileURLWithPath:[item pathToFile] isDirectory:YES] absoluteString] forKey:@"url"];

    return info;
}

- (void) mediaSource:(id<MediaSource>)mediaSource didAddItems:(NSArray*)items
{
    NSMutableArray* adds = [NSMutableArray array];
    NSMutableArray* updates = [NSMutableArray array];
    for (Disc* item in items) {
        NSString* fingerprint = [item fingerprint];
        if (fingerprint) {
            Movie* movie = [moviesByFingerprint objectForKey:fingerprint];
            if (!movie) {
                movie = [[Movie alloc] initWithItem:item];
                [moviesByFingerprint setObject:movie forKey:fingerprint];
                [movie release];
                [adds addObject:fingerprint];
            } else {
                [movie addItem:item];
                [updates addObject:fingerprint];
            }

            /*  Read in the info dictionary, and merge it with any that we've
             *  already loaded.
             */
            NSMutableDictionary* infoDictionary = [self infoDictionaryForItem:item];
            NSMutableDictionary* existingInfoDictionary = [infoDictionariesByFingerprint objectForKey:fingerprint];
            if (existingInfoDictionary) {
                // TODO:  A better merge than this.
                [existingInfoDictionary addEntriesFromDictionary:infoDictionary];
            } else {
                [infoDictionariesByFingerprint setObject:infoDictionary forKey:fingerprint];
            }
        } else {
            static NSString* pathToMDImport = @"/usr/bin/mdimport";
            [NSTask launchedTaskWithLaunchPath:pathToMDImport arguments:[NSArray arrayWithObjects:pathToMDImport, [item pathToFile], nil]];
        }
    }

    /*  Any movies that are being added will already contain the data that
     *  be sent as an update, so we can stomp on those here.
     */
    [updates removeObjectsInArray:adds];

    /*  Build and send the message.
     */
    NSMutableDictionary* message = [NSMutableDictionary dictionary];
    if ([adds count]) {
        [message setObject:[infoDictionariesByFingerprint objectsForKeys:adds notFoundMarker:[NSNull null]] forKey:@"add"];
    }
    if ([updates count]) {
        [message setObject:[infoDictionariesByFingerprint objectsForKeys:updates notFoundMarker:[NSNull null]] forKey:@"update"];
    }
    if ([message count]) {
        [protocol sendMessage:message];
    }
}

- (void) mediaSource:(id<MediaSource>)mediaSource didUpdateItems:(NSArray*)items
{
    NSMutableArray* adds = [NSMutableArray array];
    NSMutableArray* updates = [NSMutableArray array];
    NSMutableArray* deletes = [NSMutableArray array];
    for (Disc* item in items) {
        NSString* oldFingerprint = [item fingerprint];
        [item reload];
        NSString* fingerprint = [item fingerprint];
        if ([fingerprint isEqualToString:oldFingerprint]) {
            /*  A normal update.
             */
            [updates addObject:fingerprint];
        } else {
            /*  Remove this item from the movie it used to match up with.  If
             *  that causes there to be no more items for that movie, then 
             *  we'll need to delete it.
             */
            Movie* oldMovie = [moviesByFingerprint objectForKey:oldFingerprint];
            [oldMovie removeItem:item];
            if (![oldMovie hasItem]) {
                [deletes addObject:oldFingerprint];
                [moviesByFingerprint removeObjectForKey:oldFingerprint];
            }

            /*  Attempt to add this item to a movie using the new fingerprint.
             *  If a movie doesn't exist, create one and treat it like an add,
             *  otherwise, we can consider this a normal update to an existing
             *  movie.
             */
            Movie* movie = [moviesByFingerprint objectForKey:fingerprint];
            if (!movie) {
                movie = [[Movie alloc] initWithItem:item];
                [moviesByFingerprint setObject:movie forKey:fingerprint];
                [movie release];
                [adds addObject:fingerprint];
            } else {
                [movie addItem:item];
                [updates addObject:fingerprint];
            }
        }

        /*  Read in the info dictionary, and merge it with any that we've
         *  already loaded.
         */
        NSMutableDictionary* infoDictionary = [self infoDictionaryForItem:item];
        NSMutableDictionary* existingInfoDictionary = [infoDictionariesByFingerprint objectForKey:fingerprint];
        if (existingInfoDictionary) {
            [existingInfoDictionary addEntriesFromDictionary:infoDictionary];
        } else {
            [infoDictionariesByFingerprint setObject:infoDictionary forKey:fingerprint];
        }
    }

    /*  Any movies that are being added will already contain the data that
     *  be sent as an update, so we can stomp on those here.
     */
    [updates removeObjectsInArray:adds];
    
    /*  Any updates that we'd come across while we were processing cancel out
     *  pending deletes.
     */
    [deletes removeObjectsInArray:updates];

    /*  Build and send the message.
     */
    NSMutableDictionary* message = [NSMutableDictionary dictionary];
    if ([adds count]) {
        [message setObject:[infoDictionariesByFingerprint objectsForKeys:adds notFoundMarker:[NSNull null]] forKey:@"add"];
    }
    if ([updates count]) {
        [message setObject:[infoDictionariesByFingerprint objectsForKeys:updates notFoundMarker:[NSNull null]] forKey:@"update"];
    }
    if ([deletes count]) {
        [message setObject:deletes forKey:@"delete"];
    }
    if ([message count]) {
        [protocol sendMessage:message];
    }
}

- (void) mediaSource:(id<MediaSource>)mediaSource didRemoveItems:(NSArray*)items
{
    NSMutableArray* deletes = [NSMutableArray array];
    for (Disc* item in items) {
        Movie* movie = [item movie];
        if (movie) {
            [movie removeItem:item];
            if (![movie hasItem]) {
                NSString* fingerprint = [item fingerprint];
                [moviesByFingerprint removeObjectForKey:fingerprint];
                [deletes addObject:fingerprint];
            }
        }
    }

    if ([deletes count]) {
        [protocol sendMessage:[NSDictionary dictionaryWithObjectsAndKeys:
            deletes,
            @"delete",
            nil
        ]];
    }
}


#pragma mark "LibraryComProtocol" delegate methods

///
/// When the engine receives a message, get it ready
///
- (void) engineMessageWasReceived:(NSDictionary*)messageDict
{
    return;
    // Save this dict back out to the file
    NSString* fingerprint = [messageDict objectForKey:@"com_discident_fingerprint"];
    
    if (!fingerprint)
        return;
    
    Movie* movie = [moviesByFingerprint objectForKey:fingerprint];
    
    // Get the info as JSON
    NSMutableDictionary* movieDict = [NSMutableDictionary dictionaryWithDictionary:[NSDictionary dictionaryWithJSON:[NSString stringWithContentsOfFile:[[movie pathToFile] stringByAppendingPathComponent:@"_Info.json"]]]];
    
    // Combine the two
    [movieDict addEntriesFromDictionary:messageDict];
    
    // Save back out the JSON file
    NSString* outJson = [NSString stringWithObjectAsJSON:movieDict];
    [outJson writeToFile:[[movie pathToFile] stringByAppendingPathComponent:@"_Info.json"] atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
    NSLog(@"Engine wrote to file %@, contents:\n%@", [[movie pathToFile] stringByAppendingPathComponent:@"_Info.json"], outJson);
}

@end


