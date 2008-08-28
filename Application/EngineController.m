#import "EngineController.h"
#import "MessageProtocol.h"
#import "NSString+UUID.h"

@interface EngineController (Private)
- (void) _saveEntityData:(NSDictionary*)messageDict toDiscEntity:(NSManagedObject*)discMO andMovieEntity:(NSManagedObject*)movieMO;
- (void) _addMoviesData:(NSArray*)messagesArray;
- (void) _updateMoviesData:(NSArray*)messagesArray;
- (void) _deleteMoviesData:(NSArray*)messagesArray;
- (NSManagedObject*) _getDiscByFingerprint:(NSString*)fingerprint;
@end


@implementation EngineController

@synthesize engineName;
@synthesize engineAddress;
@synthesize UUID;

///
/// Init, with setting up the engine for messaging
///
- (id) initWithLocalEngine:(NSManagedObjectContext*)_managedObjectContext 
{
    NSAssert(_managedObjectContext, @"managedObjectContext must not be nil");
    if (self = [super init]) {
        UUID = [[NSString stringWithUUID] retain];
        managedObjectContext = [_managedObjectContext retain];
        
        //  Wire up our protocol
        NSPipe* pipe1 = [NSPipe pipe];
        NSPipe* pipe2 = [NSPipe pipe];
        protocol = [[MessageProtocol protocolWithDelegate:self fileHandleForReading:[pipe2 fileHandleForReading] fileHandleForWriting:[pipe1 fileHandleForWriting]] retain];

        //  Fire up the engine task
        engineTask = [[NSTask alloc] init];
        [engineTask setStandardInput:[pipe1 fileHandleForReading]];
        [engineTask setStandardOutput:[pipe2 fileHandleForWriting]];
        [engineTask setLaunchPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Engine"]];
        
        //  Make sure we listen for a termination and launch the task
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(localEngineDidTerminate:) name:(NSString*)NSTaskDidTerminateNotification object:engineTask]; 
        [engineTask launch];
        
        // Create the entity descriptions
        mediaDesc = [NSEntityDescription entityForName:@"Media" inManagedObjectContext:managedObjectContext];
        discDesc = [NSEntityDescription entityForName:@"Disc" inManagedObjectContext:managedObjectContext];
        movieDesc = [NSEntityDescription entityForName:@"Movie" inManagedObjectContext:managedObjectContext];
        
        //  Add this engine to the Core Data set
        engineName = @"Your computer";
        engineAddress = @"localhost";
        engineManagedObject = [[NSManagedObject alloc] initWithEntity:[NSEntityDescription entityForName:@"Engine" inManagedObjectContext:managedObjectContext] insertIntoManagedObjectContext:managedObjectContext];
        [engineManagedObject setValue:engineAddress forKey:@"address"];
        [engineManagedObject setValue:engineName forKey:@"niceName"];
        [engineManagedObject setValue:UUID forKey:@"UUID"];
        
        [managedObjectContext save:nil];
    }
    return self;
} 

- (void) dealloc
{
    [engineManagedObject release];
    [engineTask release];
    [UUID release];
    [managedObjectContext release];
    [protocol release];
    [super dealloc];
}

///
/// Send a message back on to the wire
///
- (void) sendMessage:(NSDictionary*)message 
{
    [protocol sendMessage:message];
}


///
/// Listen for our current engine to die
///
- (void) localEngineDidTerminate:(NSNotification*)notification 
{
    NSAlert* a = [NSAlert alertWithMessageText:@"Local Engine Quit" 
                                 defaultButton:@"OK" 
                               alternateButton:nil 
                                   otherButton:nil
                     informativeTextWithFormat:@"The local engine quit.  The whole app should."];    
    [a runModal];

    //  The task is dead, no need for a listener.
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


///
/// Close all this noise
///
- (BOOL) close 
{
    @try {
        [protocol release];
        [engineTask terminate];
        NSLog(@"Closed connection to engine and terminated engine successfully.");
        return TRUE;
    } @catch (NSException* ex) {
        NSLog(@"@%", ex);
    }
    return FALSE;
}


/// 
/// Add a new movie to the Core Data set
- (void) _addMoviesData:(NSArray*)messagesArray 
{
    for (NSDictionary* messageDict in messagesArray) {
        
        NSManagedObject* movieMO;
        NSManagedObject* discMO;
        
        BOOL movieFound = NO;
        BOOL discFound = NO;
        
        NSString* url = [messageDict objectForKey:@"url"];
        NSString* gtin = [messageDict objectForKey:@"gtin"];
        NSString* fingerprint = [messageDict objectForKey:@"com_discident_fingerprint"];
        
        // Create the new media entity
        NSManagedObject* mediaMO = [[NSManagedObject alloc] initWithEntity:mediaDesc insertIntoManagedObjectContext:managedObjectContext];
        [mediaMO setValue:url forKey:@"url"];
        [mediaMO setValue:engineManagedObject forKey:@"mediaEngine"];
        
        // Check to see if there is an existing disc entity
        NSFetchRequest* frDisc = [[NSFetchRequest alloc] init];
        [frDisc setEntity:discDesc];
        [frDisc setPredicate:[NSPredicate predicateWithFormat:@"com_discident_fingerprint == %@", fingerprint]];
        
        NSError* error;
        NSArray* results = [managedObjectContext executeFetchRequest:frDisc error:&error];
        
        if (results && [results count] > 0) {
            discFound = YES;
            discMO = [results objectAtIndex:0];
        }
        else {
            discFound = NO;
            discMO = [[NSManagedObject alloc] initWithEntity:discDesc insertIntoManagedObjectContext:managedObjectContext];
            [discMO setValue:fingerprint forKey:@"com_discident_fingerprint"];
        }
        
        [frDisc release];
        [mediaMO setValue:discMO forKey:@"mediaDisc"];
        
        if (gtin) {
            NSFetchRequest* fr = [[NSFetchRequest alloc] init];
            [fr setEntity:[NSEntityDescription entityForName:@"Movie" inManagedObjectContext:managedObjectContext]];
            [fr setPredicate:[NSPredicate predicateWithFormat:@"gtin == %@", [messageDict objectForKey:@"gtin"]]]; 
            
            [results release];
            results = [managedObjectContext executeFetchRequest:fr error:&error];

            if (results && [results count] > 0) {
                movieMO = [results objectAtIndex:0];
                movieFound = YES;
            }
            
            [fr release];
        }
        
        if (!movieFound) {
            movieMO = [[NSManagedObject alloc] initWithEntity:movieDesc insertIntoManagedObjectContext:managedObjectContext];
        }
        
        [discMO setValue:movieMO forKey:@"discMovie"];
        
        if (movieFound)
            [self _saveEntityData:messageDict toDiscEntity:discMO andMovieEntity:nil];
        else
            [self _saveEntityData:messageDict toDiscEntity:discMO andMovieEntity:movieMO];
    }
}



///
/// Update movies already in Core Data
///
- (void) _updateMoviesData:(NSArray*)messagesArray 
{
    // Always check for a movie's existance.  An update on the engine side
    // may actually be an add on the UI side.
    for (NSDictionary* message in messagesArray) {
        
        NSString* fingerprint = [message objectForKey:@"com_discident_fingerprint"];
        NSString* url = [message objectForKey:@"url"];
        
        // We want to see if there is a "disc" with this fingerprint
        // If there is, this media should just attach to it, and not update
        // anything.  If there is none, then we have to decide if we should
        // create anything.  Since the engine SHOULD be intelligent enough
        // to do this for us, we're going to simply update for right now
        NSFetchRequest* fr = [[NSFetchRequest alloc] init];
        [fr setEntity:discDesc];
        [fr setPredicate:[NSPredicate predicateWithFormat:@"com_discident_fingerprint = %@", fingerprint]];
        
        NSError* error;
        NSArray* results = [managedObjectContext executeFetchRequest:fr error:&error];
        
        if (!results || [results count] == 0) {
            NSLog(@"Update for fingerprint %@ was unable to find any discs with that value.  Disc should already be present for Update messages", 
                  fingerprint);
            continue;
        }
        
        NSManagedObject* discMO = [results objectAtIndex:0];
        
        // Now check for a media object that actually exists here.  The reason for doing so
        // is that if this object EXISTS, it's an update from say DiscIdent of Amazon and we're 
        // going to want to actually display the incoming data.
        [fr setEntity:mediaDesc];
        [fr setPredicate:[NSPredicate predicateWithFormat:@"url = %@", url]];
        
        results = [[managedObjectContext executeFetchRequest:fr error:&error] retain];
        
        NSManagedObject* mediaMO = nil;
        
        if (results && [results count] > 0) {
            // Send the updated results for a save
            [self _saveEntityData:message toDiscEntity:discMO andMovieEntity:[discMO valueForKey:@"discMovie"]];
        }
        else {
            // Create the new media object
            mediaMO = [[NSManagedObject alloc] initWithEntity:mediaDesc insertIntoManagedObjectContext:managedObjectContext];
            [mediaMO setValue:[message objectForKey:@"url"] forKey:@"url"];
            [mediaMO setValue:discMO forKey:@"mediaDisc"];
            [mediaMO release];
        }
            
        [results release];
        [fr release];
        [managedObjectContext save:nil];
        
        //id object = [engineManagedObject valueForKeyPath:@"engineMedia.mediaDisc.discMovie"];
    }
}



- (void) _deleteMoviesData:(NSArray*)messagesArray 
{
    for (NSDictionary* message in messagesArray) {

        // We want to delete only media objects unless this leaves
        // empty disc and/or movie objects.
        
        // Find the entity we want to delete by URL.  Then get its 
        // movie and disc objects first and take counts.  Finally, 
        // execute the actual deletions if necessary.
        
        NSManagedObject* mediaMO;
        NSManagedObject* discMO; 
        NSManagedObject* movieMO;
        
        NSFetchRequest* fr = [[NSFetchRequest alloc] init];
        [fr setEntity:mediaDesc];
        [fr setPredicate:[NSPredicate predicateWithFormat:@"url = %@", [message objectForKey:@"url"]]];
        
        NSError* error;
        NSArray* results = [managedObjectContext executeFetchRequest:fr error:&error];
        
        if (!results || [results count] == 0) {
            NSLog(@"Trying to delete fingerprint\n%@\nfor url\n%@\nand can't find matching Media object", 
                  [message objectForKey:@"com_discident_fingerprint"], 
                  [message objectForKey:@"url"]);
            
            continue;
        }
        
        mediaMO = [results objectAtIndex:0];
        discMO = [mediaMO valueForKey:@"mediaDisc"];
        movieMO = [discMO valueForKey:@"discMovie"];
        
        int discMediaCount;
        
        // Figure out which object to delete, as deletions will 
        // cascade
        discMediaCount = [[discMO valueForKey:@"discMedia"] count] - 1;
        
        if (0 == discMediaCount) {
            int movieDiscsCount = [[movieMO valueForKey:@"movieDiscs"] count] - 1;
            if (0 == movieDiscsCount) {
                [managedObjectContext deleteObject:movieMO];
            }
            else {
                [managedObjectContext deleteObject:discMO];
            }
        }
        else {
            [managedObjectContext deleteObject:mediaMO];
        }
        
        [managedObjectContext save:nil];
    }
}


- (NSManagedObject*) _getDiscByFingerprint:(NSString*)fingerprint       
{
    NSFetchRequest* fingerprintFR = [[NSFetchRequest alloc] init];
    [fingerprintFR setEntity:[NSEntityDescription entityForName:@"Disc" inManagedObjectContext:managedObjectContext]];
    [fingerprintFR setPredicate:[NSPredicate predicateWithFormat:@"com_discident_fingerprint == %@", fingerprint]];
    
    // Perform the fetch request
    NSError* error;
    NSArray* results = [managedObjectContext executeFetchRequest:fingerprintFR error:&error];
    
    [fingerprintFR release];
    
    if (!results) {
        NSLog(@"%@", [error localizedDescription]);
        return nil;
    }
    else if (0 == [results count]) {
        NSLog(@"No discs found for fingerprint %@", fingerprint);
        return nil;
    }
    else {
        if ([results count] > 1) {
            NSLog(@"Fingerprint %@ returned more than one disc!", fingerprint);
        }
        
        return [results objectAtIndex:0];
    }
}


- (void) _saveEntityData:(NSDictionary*)messageDict toDiscEntity:(NSManagedObject*)discMO andMovieEntity:(NSManagedObject*)movieMO
{
    [discMO setValue:[messageDict valueForKey:@"com_discident_fingerprint"] forKey:@"com_discident_fingerprint"];
    [discMO setValue:[NSNumber numberWithInt:1] forKey:@"discNumber"];

    //[discMO setValue:[messageDict objectForKey:@"url"] forKey:@"url"];
    
    if (movieMO) {
        [movieMO setValue:[messageDict objectForKey:@"title"] forKey:@"title"];
        [movieMO setValue:[messageDict objectForKey:@"gtin"] forKey:@"gtin"];
    }
    
    [managedObjectContext save:nil];
}


#pragma mark LibraryComProtocol delegate methods

///
/// A message was received and passed up here.  Do
/// something with it (probably send to the data store
///
- (void) protocol:(MessageProtocol*)protocol didReceiveMessage:(NSDictionary*)messageDict 
{
    // Check for all three keys
    if ([messageDict objectForKey:@"add"] && [[messageDict objectForKey:@"add"] isKindOfClass:[NSArray class]]) {
        [self _addMoviesData:[messageDict objectForKey:@"add"]];
    }
    if ([messageDict objectForKey:@"update"] && [[messageDict objectForKey:@"update"] isKindOfClass:[NSArray class]]) {
        [self _updateMoviesData:[messageDict objectForKey:@"update"]];
    }
    if ([messageDict objectForKey:@"delete"] && [[messageDict objectForKey:@"delete"] isKindOfClass:[NSArray class]]) {
        [self _deleteMoviesData:[messageDict objectForKey:@"delete"]];
    }
}

@end
