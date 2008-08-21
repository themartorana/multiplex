#import "Engine.h"
#import "Item.h"
#import "Movie.h"
#import "JSONKit/JSONKit.h"
#import "DiscIdent.h"
#import "LibraryComProtocol.h"

@interface Engine (Private)

- (void) _queryDidUpdate:(NSNotification*)notification;
- (void) _startTracking:(Item*)item;
- (void) _restartTracking:(Item*)item;
- (void) _stopTracking:(Item*)item;
- (void) _sendMovieUpdates:(NSArray*)updateMovies additions:(NSArray*)addMovies andDeletions:(NSArray*)deleteMovies;
- (NSArray*) _prepareMoviesForAddOrUpdate:(NSArray*)movies;
- (NSArray*) _prepareMoviesForDelete:(NSArray*)movies;

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
    [moviesByFingerprint release];
    [super dealloc];
}

static Item* newItem(MDQueryRef query, MDItemRef item, Engine* engine)
{
	return [[Item alloc] initWithMDItemRef:item];
}

- (void) run
{
	NSNotificationCenter* notificationCenter = [NSNotificationCenter defaultCenter];

    //NSLog(@"started");

	/*  Setup the query to find all of the PDF and CHM files on the discs 
	 *  directly connected to the computer.
	 */
	query = MDQueryCreate(NULL, (CFStringRef)@"kMDItemContentType == 'public.dvdmedia' || kMDItemContentType == 'dyn.ah62d4qmuhk2x43d0qv00n3dmqe'", NULL, NULL);
	MDQuerySetSearchScope(query, (CFArrayRef)[NSArray arrayWithObjects:(id)kMDQueryScopeComputer, nil], 0); 

	/*  Make sure that our progress and update notification handlers are 
	 *  properly registered.
	 */
	[notificationCenter addObserver:self selector:@selector(_queryDidUpdate:) name:(id)kMDQueryProgressNotification object:nil]; 
	[notificationCenter addObserver:self selector:@selector(_queryDidUpdate:) name:(id)kMDQueryDidFinishNotification object:nil]; 
	[notificationCenter addObserver:self selector:@selector(_queryDidUpdate:) name:(id)kMDQueryDidUpdateNotification object:nil]; 

	/*  Tell Spotlight how to create & track Item objects for us.  It will 
	 *  pass them back to us in our notifications instead of plain-jane 
	 *  MDItemRefs.
	 */
	MDQuerySetCreateResultFunction(query, (MDQueryCreateResultFunction)&newItem, self, &kCFTypeArrayCallBacks);

	/*  Tell spotlight how much and how often we would like to be updated.
	 */
	MDQueryBatchingParams batchingParameters = {
		250,		// first_max_num
		0,			// first_max_ms
		250,		// progress_max_num
		0,			// progress_max_ms
		1,			// update_max_num
		0			// update_max_ms
	};
	MDQuerySetBatchingParameters(query, batchingParameters);

	/*	Execute the (live) query in an asynchronous manner.
	 */
	MDQueryExecute(query, kMDQueryWantsUpdates);

    [super run];
}

- (void) _queryDidUpdate:(NSNotification*)notification
{
	NSDictionary* info = [notification userInfo];

	/*  Removed Items
	 */
	NSArray* removedItems = [info objectForKey:(id)kMDQueryUpdateRemovedItems];
	if (removedItems) {
        for (Item* item in removedItems) {
			[self _stopTracking:item];
        }
	}

	/*  Changed Items
	 */
	NSArray* changedItems = [info objectForKey:(id)kMDQueryUpdateChangedItems];
	if (changedItems) {
        for (Item* item in changedItems) {
			[self _restartTracking:item];
        }
	}

	/*  Added Items
	 */
	if ([[notification name] isEqualTo:(id)kMDQueryProgressNotification]) {
		int imax = MDQueryGetResultCount(query);
		for (int i = itemsProcessed; i < imax; i++) {
			Item* item = (Item*)MDQueryGetResultAtIndex(query, i);
			[self _startTracking:item];
		}
		itemsProcessed = imax;
	} else if ([[notification name] isEqualTo:(id)kMDQueryDidFinishNotification]) {
		//NSLog(@"finished");
	} else {
		NSArray* addedItems = [info objectForKey:(id)kMDQueryUpdateAddedItems];
		if (addedItems) {
            for (Item* item in addedItems) {
				[self _startTracking:item];
			}
		}
	}
}


///
/// A movie was reported by Spotlight
///
- (void) _startTracking:(Item*)item
{
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


///
/// A movie was updated
///
- (void) _restartTracking:(Item*)item
{
    [item reload];
    Movie* movie = [item movie];
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


///
/// A movie was removed
///
- (void) _stopTracking:(Item*)item
{
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


///
/// Prepare the movies sent as additions or updates
///
- (NSArray*) _prepareMoviesForAddOrUpdate:(NSArray*)movies
{
    if (!movies || 0 == [movies count])
        return nil;
    
    NSMutableArray* updatesArray = [NSMutableArray arrayWithCapacity:[movies count]];
    
    for (int i = 0; i < [movies count]; i++) {
        Movie* movie = [movies objectAtIndex:i];
        
        // Generate message
        NSString* pathToJSONFile = [[movie pathToFile] stringByAppendingPathComponent:@"_Info.json"];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:pathToJSONFile]) {
            //NSLog(@"Sent movie without _Info.json file!\nPath is: %@", pathToJSONFile);
            continue;
        }
        
        // Create the initial dictionary and values from the .json file
        NSMutableDictionary* movieDict = [NSMutableDictionary dictionaryWithDictionary:[NSDictionary dictionaryWithJSON:[NSString stringWithContentsOfFile:pathToJSONFile]]];
        
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
        [updatesArray addObject:[NSDictionary dictionaryWithDictionary:movieDict]];
    }
    
    // Return the array of dictionaries
    return [NSArray arrayWithArray:updatesArray];
}


///
/// Prepare the movies sent as dictionaries for delete
///
- (NSArray*) _prepareMoviesForDelete:(NSArray*)movies
{
    if (!movies || 0 == [movies count])
        return nil;
    
    NSMutableArray* deletesArray = [NSMutableArray arrayWithCapacity:[movies count]];
    
    for (int i = 0; i < [movies count]; i++) {
        Movie* movie = [movies objectAtIndex:i];
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


///
/// When the engine receives a message, get it ready
///
- (void) engineMessageWasReceived:(NSDictionary*)messageDict
{
    // Save this dict back out to the file
    
}


@end


