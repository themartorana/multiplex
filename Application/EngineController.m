#import "EngineController.h"
#import "MessageProtocol.h"
#import "NSString+UUID.h"

@interface EngineController (Private)
- (void) _saveEntityData:(NSDictionary*)messageDict toDiscEntity:(NSManagedObject*)discMO andMovieEntity:(NSManagedObject*)movieMO;
- (void) _addMoviesData:(NSDictionary*)add;
- (void) _updateMoviesData:(NSDictionary*)update;
- (void) _deleteMoviesData:(NSDictionary*)delete;
@end


@implementation EngineController

@synthesize engineName;
@synthesize engineAddress;
@synthesize UUID;

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
        mediaDesc = [[NSEntityDescription entityForName:@"Media" inManagedObjectContext:managedObjectContext] retain];
        discDesc = [[NSEntityDescription entityForName:@"Disc" inManagedObjectContext:managedObjectContext] retain];
        movieDesc = [[NSEntityDescription entityForName:@"Movie" inManagedObjectContext:managedObjectContext] retain];
        
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
    [mediaDesc release];
    [discDesc release];
    [movieDesc release];
    [super dealloc];
}

- (void) sendMessage:(NSDictionary*)message 
{
    [protocol sendMessage:message];
}

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

- (NSManagedObject*) findDiscByFingerprint:(NSString*)fingerprint
{
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:discDesc];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"fingerprint == %@", fingerprint]];
    NSError* error = nil;
    NSArray* results = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    [fetchRequest release];
    if (!error && [results count]) {
        return [results objectAtIndex:0];
    }
    return nil;
}

- (NSManagedObject*) findMovieByGTIN:(NSString*)gtin
{
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:movieDesc];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"gtin == %@", gtin]]; 
    NSError* error = nil;
    NSArray* results = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    [fetchRequest release];
    if (!error && [results count]) {
        return [results objectAtIndex:0];
    }
    return nil;
}

- (NSManagedObject*) findMediaByURL:(NSString*)url
{
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:mediaDesc];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"url == %@", url]]; 
    NSError* error = nil;
    NSArray* results = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    [fetchRequest release];
    if (!error && [results count]) {
        return [results objectAtIndex:0];
    }
    return nil;
}

- (void) deleteMovieIfNoMediaRemain:(NSManagedObject*)movie  
{
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:discDesc];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"movie == %@ && media.@count == 0", movie]];
    NSError* error = nil;
    NSArray* results = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    [fetchRequest release];
    if (!error && [results count] == [[movie valueForKey:@"discs"] count]) {
        [managedObjectContext deleteObject:movie];
    }
}

#pragma mark LibraryComProtocol delegate methods

- (void) protocol:(MessageProtocol*)protocol didReceiveMessage:(NSDictionary*)message 
{
    /*
     */
    NSDictionary* update = [message objectForKey:@"update"];
    if (update && [update isKindOfClass:[NSDictionary class]]) {
        for (NSString* fingerprint in update) {
            NSDictionary* info = [update objectForKey:fingerprint];
            NSDictionary* movieInfo = [info objectForKey:@"movie"];

            /*  Find or create the disc that's represented by our fingerprint.
             */
            NSManagedObject* disc = [self findDiscByFingerprint:fingerprint];
            if (!disc) {
                disc = [[[NSManagedObject alloc] initWithEntity:discDesc insertIntoManagedObjectContext:managedObjectContext] autorelease];
                [disc setValue:fingerprint forKey:@"fingerprint"];
            }
            
            /*  For each URL provided, create a media object to represent it,
             *  and attached it to our disc.
             */
            for (NSString* url in [info objectForKey:@"urls"]) {
                NSManagedObject* media = [[NSManagedObject alloc] initWithEntity:mediaDesc insertIntoManagedObjectContext:managedObjectContext];
                [media setValue:url forKey:@"url"];
                [media setValue:engineManagedObject forKey:@"engine"];
                [media setValue:disc forKey:@"disc"];
                [media release];
            }
            
            /*  Figure out which movie to attach this disc to.  We may have 
             *  created a temporary movie that could need to be deleted if 
             *  another already exists with a particular GTIN.
             */
            NSString* gtin = [movieInfo objectForKey:@"gtin"];
            NSManagedObject* movie = gtin ? [self findMovieByGTIN:gtin] : nil;
            if (movie) {
                NSManagedObject* movieForDisc = [disc valueForKey:@"movie"];
                if (movie != movieForDisc) {
                    [disc setValue:movie forKey:@"movie"];
                    if (movieForDisc) {
                        [self deleteMovieIfNoMediaRemain:movieForDisc];
                    }
                }
            } else {
                movie = [disc valueForKey:@"movie"];
                if (!movie) {
                    movie = [[[NSManagedObject alloc] initWithEntity:movieDesc insertIntoManagedObjectContext:managedObjectContext] autorelease];
                }
                if (gtin) {
                    [movie setValue:gtin forKey:@"gtin"];
                }
                [disc setValue:movie forKey:@"movie"];
            }
            
            /*  Set any movie-related properties.
             */
            NSString* aspect_ratio = [movieInfo objectForKey:@"aspect_ratio"];
            if (aspect_ratio) {
                [movie setValue:aspect_ratio forKey:@"aspectRatio"];
            }
            NSString* review = [movieInfo objectForKey:@"review"];
            if (review) {
                [movie setValue:review forKey:@"review"];
            }
            NSString* synopsis = [movieInfo objectForKey:@"synopsis"];
            if (synopsis) {
                [movie setValue:synopsis forKey:@"synopsis"];
            }
            NSString* title = [movieInfo objectForKey:@"title"];
            if (title) {
                [movie setValue:title forKey:@"title"];
            }
            
            /*  If there is a "discs" dictionary present, enumerate it's keys,
             *  creating disc objects and associating them with the movie that
             *  we're attaching ourselves to.
             */
            NSDictionary* discInfo = [movieInfo objectForKey:@"discs"];
            for (NSString* discInfoFingerprint in discInfo) {
                NSDictionary* otherDiscInfo = [discInfo objectForKey:discInfoFingerprint];
                NSManagedObject* disc = [self findDiscByFingerprint:discInfoFingerprint];
                if (!disc) {
                    disc = [[[NSManagedObject alloc] initWithEntity:discDesc insertIntoManagedObjectContext:managedObjectContext] autorelease];
                    [disc setValue:discInfoFingerprint forKey:@"fingerprint"];
                }
                NSString* tag = [otherDiscInfo objectForKey:@"tag"];
                if (tag && [tag length] == 2) {
                    int number = [tag characterAtIndex:0] - '0';
                    if (number >= 1 && number <= 9) {
                        [disc setValue:[NSNumber numberWithInt:number] forKey:@"number"];
                    }
                    [disc setValue:[tag substringFromIndex:1] forKey:@"side"];
                }
                NSManagedObject* movieForDisc = [disc valueForKey:@"movie"];
                if (movie != movieForDisc) {
                    [disc setValue:movie forKey:@"movie"];
                    if (movieForDisc) {
                        [self deleteMovieIfNoMediaRemain:movieForDisc];
                    }
                }
            }
        }
    }

    /*
     */
    NSDictionary* delete = [message objectForKey:@"delete"];
    if (delete && [delete isKindOfClass:[NSDictionary class]]) {
        for (NSString* fingerprint in delete) {
            NSDictionary* info = [delete objectForKey:fingerprint];
            for (NSString* url in [info objectForKey:@"urls"]) {
                NSManagedObject* media = [self findMediaByURL:url];
                if (media) {
                    [managedObjectContext deleteObject:media];
                    NSManagedObject* disc = [media valueForKey:@"disc"];
                    if (1 == [[disc valueForKey:@"media"] count]) {
                        NSManagedObject* movie = [disc valueForKey:@"movie"];
                        [self deleteMovieIfNoMediaRemain:movie];
                    }
                }
            }
        }
    }
    
    [managedObjectContext save:nil];
}

@end