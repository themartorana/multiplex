#import "Engine.h"
#import "Item.h"
#import "Movie.h"
#import "DVDMediaSource.h"
#import "PhysicalMediaSource.h"
#import "JSONKit/JSONKit.h"
#import "DiscIdent.h"
#import "LibraryComProtocol.h"
#import "NSString+DiscIdent.h"

@interface Engine (Private)
- (NSArray*) _prepareMoviesForAddOrUpdate:(NSArray*)movies;
- (NSArray*) _prepareMoviesForDelete:(NSArray*)movies;
- (void) _sendMovieUpdates:(NSArray*)updateMovies additions:(NSArray*)addMovies andDeletions:(NSArray*)deleteMovies;
@end

@implementation Engine

- (id) init
{
    if (self = [super init]) {
        moviesByFingerprint = [[NSMutableDictionary alloc] init];
        protocol = [[LibraryComProtocol alloc] init];
        
        // Set up the protocol
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
    [super dealloc];
}

- (void) run
{
    NSArray* mediaSources = [NSArray arrayWithObjects:
        [[DVDMediaSource alloc] init],
        [[PhysicalMediaSource alloc] init],
        nil
    ];

    for (id<MediaSource> mediaSource in mediaSources) {
        [mediaSource setDelegate:self];
        [mediaSource start];
    }

    [super run];
}

- (void) mediaSource:(id<MediaSource>)mediaSource didAddItems:(NSArray*)items
{
    for (Item* item in items) {
        NSString* fingerprint = [item fingerprint];
        NSFileManager* manager = [NSFileManager defaultManager];
        if (fingerprint && [manager fileExistsAtPath:[[item pathToFile] stringByAppendingPathComponent:@"_Info.json"] isDirectory:NO]) {
            Movie* movie = [moviesByFingerprint objectForKey:fingerprint];
            if (!movie) {
                movie = [[Movie alloc] initWithItem:item];
                [moviesByFingerprint setObject:movie forKey:fingerprint];
                [movie release];
            } else {
                [movie addItem:item];
            }
            //NSLog(@"%@ + %@", [movie fingerprint], [NSURL fileURLWithPath:[item pathToFile] isDirectory:YES]);
            
            // Check to see if we have a GTIN
            NSDictionary* dictToCheck = [NSDictionary dictionaryWithJSON:[NSString stringWithContentsOfFile:[[movie pathToFile] stringByAppendingPathComponent:@"_Info.json"]]];
            if (![dictToCheck objectForKey:@"gtin"]) {
                DiscIdent* di = [[DiscIdent alloc] init];
                [di getMovieInfoFromDiscIdentUsingFingerprint:[movie fingerprint] pathToMovie:[movie pathToFile]];
            }
            
            [self _sendMovieUpdates:nil additions:[NSArray arrayWithObject:movie] andDeletions:nil];
        } else {
            static NSString* pathToMDImport = @"/usr/bin/mdimport";
            [NSTask launchedTaskWithLaunchPath:pathToMDImport arguments:[NSArray arrayWithObjects:pathToMDImport, [item pathToFile], nil]];
        }
    }
}

- (void) mediaSource:(id<MediaSource>)mediaSource didUpdateItems:(NSArray*)items
{
    for (Item* item in items) {
        [item reload];
        Movie* movie = [item movie];
        
        if (movie.listenForLoopback) {
            movie.listenForLoopback = NO;
            return;
        }
        
        NSString* fingerprint = [item fingerprint];
        if (fingerprint) {
            if (movie && ![fingerprint isEqual:[movie fingerprint]]) {
                //NSLog(@"%@ - %@", [movie fingerprint], [NSURL fileURLWithPath:[item pathToFile] isDirectory:YES]);
                [self _sendMovieUpdates:nil additions:nil andDeletions:[NSArray arrayWithObject:movie]];
                [movie removeItem:item];
                if (![movie hasItem]) {
                    [moviesByFingerprint removeObjectForKey:movie];
                }
            }
            movie = [moviesByFingerprint objectForKey:fingerprint];
            if (!movie) {
                movie = [[Movie alloc] initWithItem:item];
                [moviesByFingerprint setObject:movie forKey:fingerprint];
                [movie release];
            } else {
                [movie addItem:item];
            }
            //NSLog(@"%@ + %@", [movie fingerprint], [NSURL fileURLWithPath:[item pathToFile] isDirectory:YES]);
            [self _sendMovieUpdates:[NSArray arrayWithObject:movie] additions:nil andDeletions:nil];
        }
    }
}

- (void) mediaSource:(id<MediaSource>)mediaSource didRemoveItems:(NSArray*)items
{
    for (Item* item in items) {
        Movie* movie = [item movie];
        if (movie) {
            //NSLog(@"%@ - %@", [movie fingerprint], [NSURL fileURLWithPath:[item pathToFile] isDirectory:YES]);
            [self _sendMovieUpdates:nil additions:nil andDeletions:[NSArray arrayWithObject:movie]];
            [movie removeItem:item];
            if (![movie hasItem]) {
                [moviesByFingerprint removeObjectForKey:movie];
            }
        }
    }
}

#pragma mark To Be Refactored

///
/// Prepare the movies sent as additions or updates
///
- (NSArray*) _prepareMoviesForAddOrUpdate:(NSArray*)movies
{
    if (!movies || 0 == [movies count])
        return nil;
    
    NSMutableArray* addUpdatesArray = [NSMutableArray arrayWithCapacity:[movies count]];
    
    for (Movie* movie in movies) {
        // Generate message
        
        NSMutableDictionary* movieDict;
        
        if (![movie isPhysicalMedia]) {
            NSString* pathToJSONFile = [[movie pathToFile] stringByAppendingPathComponent:@"_Info.json"];
            
            if (![[NSFileManager defaultManager] fileExistsAtPath:pathToJSONFile]) {
                //NSLog(@"Sent movie without _Info.json file!\nPath is: %@", pathToJSONFile);
                continue;
            }
            
            // Create the initial dictionary and values from the .json file
            movieDict = [NSMutableDictionary dictionaryWithDictionary:[NSDictionary dictionaryWithJSON:[NSString stringWithContentsOfFile:pathToJSONFile]]];
        }
        else {
            movieDict = [NSMutableDictionary dictionaryWithObject:[movie fingerprint] forKey:@"com_discident_fingerprint"];
        }
        
        // Eventually this can be changed depending on whether this is a bonjour setting or not
        [movieDict setObject:[[NSURL fileURLWithPath:[movie pathToFile] isDirectory:YES] absoluteString] forKey:@"url"];
        
        // Check for the title
        if (![movieDict objectForKey:@"title"]) {
            NSString* pathToFile = [movie pathToFile];
            if ([pathToFile rangeOfString:@"/" options:NSBackwardsSearch].location == ([pathToFile length] - 1))
                pathToFile = [pathToFile substringWithRange:NSMakeRange(0, [pathToFile length] - 1)];
            
            int startlocation = [pathToFile rangeOfString:@"/" options:NSBackwardsSearch].location + 1;
            NSString* title = [pathToFile substringWithRange:NSMakeRange(startlocation, [pathToFile length] - startlocation)];
            
            [movieDict setObject:title forKey:@"title"];
        }
        
        // Send
        [addUpdatesArray addObject:[NSDictionary dictionaryWithDictionary:movieDict]];
    }
    
    // Return the array of dictionaries
    return [NSArray arrayWithArray:addUpdatesArray];
}


///
/// Prepare the movies sent as dictionaries for delete
///
- (NSArray*) _prepareMoviesForDelete:(NSArray*)movies
{
    if (!movies || 0 == [movies count])
        return nil;
    
    NSMutableArray* deletesArray = [NSMutableArray arrayWithCapacity:[movies count]];
    
    for (Movie* movie in movies) {
        NSDictionary* dict = [NSDictionary dictionaryWithObject:[movie fingerprint] forKey:@"com_discident_fingerprint"];
        [deletesArray addObject:dict];
    }
    
    return [NSArray arrayWithArray:deletesArray];
}

///
/// Take any updates that come in, prepare them, and send them out
/// 
- (void) _sendMovieUpdates:(NSArray*)updateMovies additions:(NSArray*)addMovies andDeletions:(NSArray*)deleteMovies
{
    NSArray* _addMovies = [self _prepareMoviesForAddOrUpdate:addMovies];
    NSArray* _updateMovies = [self _prepareMoviesForAddOrUpdate:updateMovies];
    NSArray* _deleteMovies = [self _prepareMoviesForDelete:deleteMovies];
    
    NSMutableDictionary* dictToSend = [NSMutableDictionary dictionaryWithCapacity:3];
    if (_addMovies) {
        [dictToSend setObject:_addMovies forKey:@"add"];
    }
    if (_updateMovies) {
        [dictToSend setObject:_updateMovies forKey:@"update"];
    }
    if (_deleteMovies) {
        [dictToSend setObject:_deleteMovies forKey:@"delete"];
    }
    
    //NSString* jsonString = [NSString stringWithObjectAsJSON:dictToSend];
    //NSLog(@"%@", jsonString);
    //const char* s = [stringToSend cStringUsingEncoding:NSUTF8StringEncoding];
    //printf("%d\n%s\n", strlen(s) + 1, s);
    
    [protocol sendMessage:dictToSend];
}


#pragma mark "LibraryComProtocol" delegate methods

///
/// When the engine receives a message, get it ready
///
- (void) engineMessageWasReceived:(NSDictionary*)messageDict
{
    // Save this dict back out to the file
    NSString* fingerprint = [messageDict objectForKey:@"com_discident_fingerprint"];
    
    if (!fingerprint)
        return;
    
    Movie* movie = [moviesByFingerprint objectForKey:fingerprint];
    movie.listenForLoopback = YES;
    
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


