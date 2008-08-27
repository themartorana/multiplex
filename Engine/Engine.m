#import "Engine.h"
#import "Disc.h"
#import "DVDMediaSource.h"
#import "PhysicalMediaSource.h"
#import "JSONKit/JSONKit.h"
#import "DiscIdentQuery.h"
#import "LibraryComProtocol.h"
#import "NSString+DiscIdent.h"

@implementation Engine

- (id) init
{
    if (self = [super init]) {
        discsByFingerprint = [[NSMutableDictionary alloc] init];
        infoDictionariesByFingerprint = [[NSMutableDictionary alloc] init];
        
        // Set up the protocol
        protocol = [[LibraryComProtocol alloc] init];
        //[protocol setFileHandleForReading:[NSFileHandle fileHandleWithStandardInput]];
        [protocol setFileHandleForWriting:[NSFileHandle fileHandleWithStandardOutput]];
        [protocol setDelegate:self];
    }
    return self;
}

- (void) dealloc
{    
    [protocol release];
    [discsByFingerprint release];
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

- (NSMutableDictionary*) infoDictionaryForMedia:(Media*)media  
{
    /*  Attempt to load the Info.json from the filesystem.  If this fails,
     *  we create a new, empty dictionary containing just the fingerprint.
     */
    NSMutableDictionary* info = nil;
    NSString* pathToJSONFile = [[media pathToFile] stringByAppendingPathComponent:@"_Info.json"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:pathToJSONFile]) {
        info = [NSDictionary dictionaryWithJSON:[NSString stringWithContentsOfFile:pathToJSONFile]];
    }
    if (!info) {
        info = [NSMutableDictionary dictionaryWithObject:[media fingerprint] forKey:(id)kMDDiscDiscIdentFingerprint];
    } else if (![info objectForKey:(id)kMDDiscDiscIdentFingerprint]) {
        [info setObject:[media fingerprint] forKey:(id)kMDDiscDiscIdentFingerprint];
    }

    /*  All discs should have a title, even if it's just one that's been
     *  derived from the (possibly crappy) name in the filesystem.
     */
    if (![info objectForKey:@"title"]) {
        NSString* title = [[[[media pathToFile] lastPathComponent] stringByDeletingPathExtension] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]];
        if (!title || ![title length]) {
            title = @"Untitled Movie";
        }
        [info setObject:title forKey:@"title"];
    }

    /*  Every disc has an URL.
     */
    [info setObject:[[NSURL fileURLWithPath:[media pathToFile] isDirectory:YES] absoluteString] forKey:@"url"];

    return info;
}

- (void) mediaSource:(id<MediaSource>)mediaSource didAddMedia:(NSArray*)arrayOfMedia
{
    NSMutableSet* adds = [NSMutableSet set];
    NSMutableSet* updates = [NSMutableSet set];
    for (Media* media in arrayOfMedia) {
        NSString* fingerprint = [media fingerprint];
        
        if (fingerprint) {
            Disc* disc = [discsByFingerprint objectForKey:fingerprint];
            if (!disc) {
                disc = [[Disc alloc] initWithMedia:media];
                [discsByFingerprint setObject:disc forKey:fingerprint];
                [disc release];
                [adds addObject:fingerprint];
            } else {
                [disc addMedia:media];
                [updates addObject:fingerprint];
            }

            /*  Read in the info dictionary, and merge it with any that we've
             *  already loaded.
             */
            NSMutableDictionary* infoDictionary = [self infoDictionaryForMedia:media];
            NSMutableDictionary* existingInfoDictionary = [infoDictionariesByFingerprint objectForKey:fingerprint];
            if (existingInfoDictionary) {
                // TODO:  A better merge than this.
                [existingInfoDictionary addEntriesFromDictionary:infoDictionary];
            } else {
                [infoDictionariesByFingerprint setObject:infoDictionary forKey:fingerprint];
            }
        } else {
            static NSString* pathToMDImport = @"/usr/bin/mdimport";
            [NSTask launchedTaskWithLaunchPath:pathToMDImport arguments:[NSArray arrayWithObjects:pathToMDImport, [media pathToFile], nil]];
        }
    }

    /*  Any movies that are being added will already contain the data that
     *  be sent as an update, so we can stomp on those here.
     */
    [updates minusSet:adds];

    /*  Build and send the message.
     */
    NSMutableDictionary* message = [NSMutableDictionary dictionary];
    if ([adds count]) {
        [message setObject:[infoDictionariesByFingerprint objectsForKeys:[adds allObjects] notFoundMarker:[NSNull null]] forKey:@"add"];
    }
    if ([updates count]) {
        [message setObject:[infoDictionariesByFingerprint objectsForKeys:[updates allObjects] notFoundMarker:[NSNull null]] forKey:@"update"];
    }
    if ([message count]) {
        [protocol sendMessage:message];
    }
}

- (void) mediaSource:(id<MediaSource>)mediaSource didUpdateMedia:(NSArray*)arrayOfMedia
{
    NSMutableSet* adds = [NSMutableSet set];
    NSMutableSet* updates = [NSMutableSet set];
    NSMutableSet* deletes = [NSMutableSet set];
    for (Media* media in arrayOfMedia) {
        NSString* oldFingerprint = [media fingerprint];
        [media reload];
        NSString* fingerprint = [media fingerprint];
        if ([fingerprint isEqualToString:oldFingerprint]) {
            /*  A normal update.
             */
            [updates addObject:fingerprint];
        } else {
            /*  Remove this disc from the movie it used to match up with.  If
             *  that causes there to be no more discs for that movie, then 
             *  we'll need to delete it.
             */
            if (oldFingerprint) {
                Disc* oldMovie = [discsByFingerprint objectForKey:oldFingerprint];
                [oldMovie removeMedia:media];
                if (![oldMovie hasDisc]) {
                    [deletes addObject:oldFingerprint];
                    [discsByFingerprint removeObjectForKey:oldFingerprint];
                }
            }

            /*  Attempt to add this disc to a movie using the new fingerprint.
             *  If a movie doesn't exist, create one and treat it like an add,
             *  otherwise, we can consider this a normal update to an existing
             *  movie.
             */
            Disc* disc = [discsByFingerprint objectForKey:fingerprint];
            if (!disc) {
                disc = [[Disc alloc] initWithMedia:media];
                [discsByFingerprint setObject:disc forKey:fingerprint];
                [disc release];
                [adds addObject:fingerprint];
            } else {
                [disc addMedia:media];
                [updates addObject:fingerprint];
            }
        }

        /*  Read in the info dictionary, and merge it with any that we've
         *  already loaded.
         */
        NSMutableDictionary* infoDictionary = [self infoDictionaryForMedia:media];
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
    [updates minusSet:adds];
    
    /*  Any updates that we'd come across while we were processing cancel out
     *  pending deletes.
     */
    [deletes minusSet:updates];

    /*  Build and send the message.
     */
    NSMutableDictionary* message = [NSMutableDictionary dictionary];
    if ([adds count]) {
        [message setObject:[infoDictionariesByFingerprint objectsForKeys:[adds allObjects] notFoundMarker:[NSNull null]] forKey:@"add"];
    }
    if ([updates count]) {
        [message setObject:[infoDictionariesByFingerprint objectsForKeys:[updates allObjects] notFoundMarker:[NSNull null]] forKey:@"update"];
    }
    if ([deletes count]) {
        [message setObject:[deletes allObjects] forKey:@"delete"];
    }
    if ([message count]) {
        [protocol sendMessage:message];
    }
}

- (void) mediaSource:(id<MediaSource>)mediaSource didRemoveMedia:(NSArray*)arrayOfMedia
{
    NSMutableArray* deletes = [NSMutableArray array];
    for (Media* media in arrayOfMedia) {
        Disc* disc = [media disc];
        if (disc) {
            [disc removeMedia:media];
            if (![disc hasDisc]) {
                NSString* fingerprint = [media fingerprint];
                [discsByFingerprint removeObjectForKey:fingerprint];
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
    NSString* fingerprint = [messageDict objectForKey:(id)kMDDiscDiscIdentFingerprint];
    
    if (!fingerprint)
        return;
    
    Disc* movie = [discsByFingerprint objectForKey:fingerprint];
    
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


