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
        
        //  Add this engine to the Core Data set
        engineName = @"Your computer";
        engineAddress = @"localhost";
        engineManagedObject = [[NSManagedObject alloc] initWithEntity:[NSEntityDescription entityForName:@"Engine" inManagedObjectContext:managedObjectContext] insertIntoManagedObjectContext:managedObjectContext];
        [engineManagedObject setValue:engineAddress forKey:@"address"];
        [engineManagedObject setValue:engineName forKey:@"niceName"];
        [engineManagedObject setValue:UUID forKey:@"UUID"];
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
        NSEntityDescription* movieDesc = [NSEntityDescription entityForName:@"Movie" inManagedObjectContext:managedObjectContext];
        NSEntityDescription* discDesc = [NSEntityDescription entityForName:@"Disc" inManagedObjectContext:managedObjectContext];

        NSManagedObject* movieMO;
        BOOL movieFound = NO;
        
        NSString* gtin = [messageDict objectForKey:@"gtin"];
        NSString* fingerprint = [messageDict objectForKey:@"com_discident_fingerprint"];
        
        if (gtin) {
            NSFetchRequest* fr = [[NSFetchRequest alloc] init];
            [fr setEntity:[NSEntityDescription entityForName:@"Movie" inManagedObjectContext:managedObjectContext]];
            [fr setPredicate:[NSPredicate predicateWithFormat:@"gtin == %@", [messageDict objectForKey:@"gtin"]]]; 
            
            NSError* error;
            NSArray* results = [managedObjectContext executeFetchRequest:fr error:&error];
            
            if (results && [results count] > 0) {
                movieMO = [results objectAtIndex:0];
                movieFound = YES;
            }
            
            [fr release];
        }
         
        
        if (!movieFound) {
            movieMO = [[NSManagedObject alloc] initWithEntity:movieDesc insertIntoManagedObjectContext:managedObjectContext];
            [movieMO setValue:engineManagedObject forKey:@"movieEngine"];
        }
        
        NSManagedObject* discMO = [[NSManagedObject alloc] initWithEntity:discDesc insertIntoManagedObjectContext:managedObjectContext];  
        
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
        NSManagedObject* discMO = [self _getDiscByFingerprint:[message objectForKey:@"com_discident_fingerprint"]];
        if (discMO) {
            // Update the data
            [self _saveEntityData:message toDiscEntity:discMO andMovieEntity:[discMO valueForKey:@"discMovie"]];
        }
    }
}



- (void) _deleteMoviesData:(NSArray*)messagesArray 
{
    // First get the disc
    for (NSString* fingerprint in messagesArray) {
                
        // Get the disc
        NSManagedObject* discMO = [self _getDiscByFingerprint:fingerprint];
        
        if (discMO) {
            // Get the movie above
            NSManagedObject* movieMO = [discMO valueForKey:@"discMovie"];
            //NSManagedObjectID* movieID = [movieMO objectID];
            //[movieMO release];
            
            // Remove the disc
            [managedObjectContext deleteObject:discMO];
            
            // Check to see if the movie has any more relationships
            //NSManagedObject* relookMO = [_nsmoc objectWithID:movieID]; 
            [managedObjectContext commitEditing];
            [managedObjectContext refreshObject:movieMO mergeChanges:YES];
            
            NSArray* s = [[movieMO valueForKey:@"movieDiscs"] allObjects];
            BOOL shouldDelete = YES;
            for (int j = 0; j < [s count]; j++) {
                if (![[s objectAtIndex:j] isDeleted]) {
                    shouldDelete = NO;
                    break;
                }
            }
            
            if (shouldDelete) {
                [managedObjectContext deleteObject:movieMO];
            }
        }
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

    [discMO setValue:[messageDict objectForKey:@"url"] forKey:@"url"];
    
    if (movieMO) {
        [movieMO setValue:engineManagedObject forKey:@"movieEngine"];
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
