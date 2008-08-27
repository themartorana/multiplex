//
//  EngineController.m
//  Library
//
//  Created by David Martorana on 8/8/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MessageProtocol.h"
#import "EngineController.h"

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
- (id) initWithLocalEngine:(NSManagedObjectContext*)managedObjectContext {
     if (!(self = [super init]))
         return nil;
    
    [self generateUUID];
    
    _nsmoc = managedObjectContext;
    
    // Engine name
    engineName = @"Your computer";
    engineAddress = @"localhost";
    
    // Create the LibraryComProtocol to communicate over
    _protocol = [[MessageProtocol alloc] init];
    [_protocol setDelegate:self];
    
    // Launch the engine NSTask
    _engineTask = [[NSTask alloc] init];
        
    NSPipe* pipe1 = [NSPipe pipe];
    _protocol.fileHandleForWriting = [pipe1 fileHandleForWriting];
    [_engineTask setStandardInput:[pipe1 fileHandleForReading]];
    
    NSPipe* pipe2 = [NSPipe pipe];
    _protocol.fileHandleForReading = [pipe2 fileHandleForReading];
    [_engineTask setStandardOutput:[pipe2 fileHandleForWriting]];
    
    NSString* pathToEngine = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Engine"];
    [_engineTask setLaunchPath:pathToEngine];
    
    // Make sure we listen for a termination
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(localEngineDidTerminate:) 
                                                 name:(NSString*)NSTaskDidTerminateNotification 
                                               object:_engineTask]; 
    
    [_engineTask launch];
    
    [self addEntityDescription];
    
    return self;
} 


///
/// Init this engine to talk over bonjour
/// 
- (id) initWithBonjourEngine 
{
    // Nada for now
    return nil;
}


///
/// Generate a UUID for this engine
- (void) generateUUID
{
    CFUUIDRef uuidRef = CFUUIDCreate(kCFAllocatorDefault);
    UUID = (NSString*)CFUUIDCreateString(kCFAllocatorDefault, uuidRef);
    
    CFRelease(uuidRef);
}

///
/// Add this engine to the Core Data set
///
- (void) addEntityDescription
{
    NSEntityDescription* ed = [NSEntityDescription entityForName:@"Engine" inManagedObjectContext:_nsmoc];
    NSManagedObject* obj = [[NSManagedObject alloc] initWithEntity:ed insertIntoManagedObjectContext:_nsmoc];
    
    _engineManagedObject = obj;
    
    [obj setValue:engineAddress forKey:@"address"];
    [obj setValue:engineName forKey:@"niceName"];
    [obj setValue:UUID forKey:@"UUID"];
}


///
/// Send a message back on to the wire
///
- (void) sendAMessage:(NSDictionary*)dict 
{
    [_protocol sendMessage:dict];
}


///
/// Listen for our current engine to die
///
- (void) localEngineDidTerminate:(NSNotification*)notification 
{
    // Show a notification
    NSAlert* a = [NSAlert alertWithMessageText:@"Local Engine Quit" 
                                 defaultButton:@"OK" 
                               alternateButton:nil 
                                   otherButton:nil
                     informativeTextWithFormat:@"The local engine quit.  The whole app should."];    
    
    [a runModal];
}


///
/// Close all this noise
///
- (BOOL) close 
{
    @try
    {
        [_protocol release];
        [_engineTask terminate];
        
        NSLog(@"Closed connection to engine and terminated engine successfully.");
    }
    @catch (NSException* ex) {
        NSLog(@"@%", ex);
        return FALSE;
    }
    
    return TRUE;
}


/// 
/// Add a new movie to the Core Data set
- (void) _addMoviesData:(NSArray*)messagesArray 
{
    for (NSDictionary* messageDict in messagesArray) {
        NSEntityDescription* movieDesc = [NSEntityDescription entityForName:@"Movie" inManagedObjectContext:_nsmoc];
        NSEntityDescription* discDesc = [NSEntityDescription entityForName:@"Disc" inManagedObjectContext:_nsmoc];

        NSManagedObject* movieMO;
        BOOL movieFound = NO;
        
        NSString* gtin = [messageDict objectForKey:@"gtin"];
        NSString* fingerprint = [messageDict objectForKey:@"com_discident_fingerprint"];
        
        if (gtin) {
            NSFetchRequest* fr = [[NSFetchRequest alloc] init];
            [fr setEntity:[NSEntityDescription entityForName:@"Movie" inManagedObjectContext:_nsmoc]];
            [fr setPredicate:[NSPredicate predicateWithFormat:@"gtin == %@", [messageDict objectForKey:@"gtin"]]]; 
            
            NSError* error;
            NSArray* results = [_nsmoc executeFetchRequest:fr error:&error];
            
            if (results && [results count] > 0) {
                movieMO = [results objectAtIndex:0];
                movieFound = YES;
            }
            
            [fr release];
        }
         
        
        if (!movieFound) {
            movieMO = [[NSManagedObject alloc] initWithEntity:movieDesc insertIntoManagedObjectContext:_nsmoc];
            [movieMO setValue:_engineManagedObject forKey:@"movieEngine"];
        }
        
        NSManagedObject* discMO = [[NSManagedObject alloc] initWithEntity:discDesc insertIntoManagedObjectContext:_nsmoc];  
        
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
            [_nsmoc deleteObject:discMO];
            
            // Check to see if the movie has any more relationships
            //NSManagedObject* relookMO = [_nsmoc objectWithID:movieID]; 
            [_nsmoc commitEditing];
            [_nsmoc refreshObject:movieMO mergeChanges:YES];
            
            NSArray* s = [[movieMO valueForKey:@"movieDiscs"] allObjects];
            BOOL shouldDelete = YES;
            for (int j = 0; j < [s count]; j++) {
                if (![[s objectAtIndex:j] isDeleted]) {
                    shouldDelete = NO;
                    break;
                }
            }
            
            if (shouldDelete) {
                [_nsmoc deleteObject:movieMO];
            }
        }
    }
}


- (NSManagedObject*) _getDiscByFingerprint:(NSString*)fingerprint       
{
    NSFetchRequest* fingerprintFR = [[NSFetchRequest alloc] init];
    [fingerprintFR setEntity:[NSEntityDescription entityForName:@"Disc" inManagedObjectContext:_nsmoc]];
    [fingerprintFR setPredicate:[NSPredicate predicateWithFormat:@"com_discident_fingerprint == %@", fingerprint]];
    
    // Perform the fetch request
    NSError* error;
    NSArray* results = [_nsmoc executeFetchRequest:fingerprintFR error:&error];
    
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
        [movieMO setValue:_engineManagedObject forKey:@"movieEngine"];
        [movieMO setValue:[messageDict objectForKey:@"title"] forKey:@"title"];
        [movieMO setValue:[messageDict objectForKey:@"gtin"] forKey:@"gtin"];
    }
    
    [_nsmoc save:nil];
}




///
/// Close up shop
///
- (void) dealloc
{
    [super dealloc];
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
