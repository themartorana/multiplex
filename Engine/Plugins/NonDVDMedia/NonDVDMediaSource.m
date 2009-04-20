#import "NonDVDMediaSource.h"
#import <JSONKit/JSONKit.h>
#import <Toolkit/Toolkit.h>
#import <sys/stat.h>

static CFStringRef kMDItemMultiplexNonDVDFingerprint = (CFStringRef)@"com_multiplexapp_nonDVDFingerprint";

@interface NSDictionary (PlusPlus)

- (id) objectForMetaKey:(NSString*)key;

@end

@implementation NSDictionary (PlusPlus)

- (id) objectForMetaKey:(NSString*)key
{
    id object = [self objectForKey:key];
    if (!object) {
        NSDictionary* meta = [self objectForKey:@"meta"];
        for (NSString* metaKey in meta) {
            if (object = [meta objectForKey:metaKey]) {
                break;
            }
        }
    }
    return object;
}

@end

static MediaFile* newSpotlightItem(MDQueryRef query, MDItemRef item, NonDVDMediaSource* mediaSource)
{
    MediaFile* media = [[MediaFile alloc] initWithMediaSource:mediaSource mediaInfo:[[NSMutableDictionary alloc] initWithObjectsAndKeys:(id)item, @"item", nil]];
    [mediaSource reloadMedia:media];
    return media;
}

@implementation NonDVDMediaSource
@synthesize delegate;

- (void) dealloc
{
    if (query) {
        MDQueryStop(query);
        CFRelease(query);
    }
    [super dealloc];
}

- (void) start
{
    NSAssert(query == nil, @"NonDVDMediaSource already started.");
    
    NSNotificationCenter* notificationCenter = [NSNotificationCenter defaultCenter];
    
    /*  Setup the query to find all of the PDF and CHM files on the discs 
     *  directly connected to the computer.
     */
    query = MDQueryCreate(NULL, (CFStringRef)[NSString stringWithFormat:@"%@ = '*'", kMDItemMultiplexNonDVDFingerprint], NULL, NULL);
    MDQuerySetSearchScope(query, (CFArrayRef)[NSArray arrayWithObjects:(id)kMDQueryScopeComputer, nil], 0); 
    
    /*  Make sure that our progress and update notification handlers are 
     *  properly registered.
     */
    [notificationCenter addObserver:self selector:@selector(_queryDidUpdate:) name:(id)kMDQueryProgressNotification object:nil]; 
    [notificationCenter addObserver:self selector:@selector(_queryDidFinish:) name:(id)kMDQueryDidFinishNotification object:nil]; 
    [notificationCenter addObserver:self selector:@selector(_queryDidUpdate:) name:(id)kMDQueryDidUpdateNotification object:nil]; 
    
    /*  Tell Spotlight how to create & track Item objects for us.  It will 
     *  pass them back to us in our notifications instead of plain-jane 
     *  MDItemRefs.
     */
    MDQuerySetCreateResultFunction(query, (MDQueryCreateResultFunction)&newSpotlightItem, self, &kCFTypeArrayCallBacks);
    
    /*  Tell spotlight how much and how often we would like to be updated.
     */
    MDQueryBatchingParams batchingParameters = {
        250,    // first_max_num
        1000,   // first_max_ms
        250,    // progress_max_num
        1000,   // progress_max_ms
        1,      // update_max_num
        1000    // update_max_ms
    };
    MDQuerySetBatchingParameters(query, batchingParameters);
    
    /*    Execute the (live) query in an asynchronous manner.
     */
    MDQueryExecute(query, kMDQueryWantsUpdates);
}

- (void) stop
{
    /*  Shutdown our spotlight notification handlers and disable the query.
     */
    NSNotificationCenter* notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self];
    MDQueryDisableUpdates(query);
    
    /*  Notify our delegate that all of the items that we're currently tracking
     *  will no longer be available.
     */
    int count = MDQueryGetResultCount(query);
    if (count) {
        NSMutableArray* removedDiscs = [NSMutableArray arrayWithCapacity:count];
        while (count-- > 0) {
            [removedDiscs addObject:(MediaFile*)MDQueryGetResultAtIndex(query, count)];
        }
        [delegate mediaFileSource:self didRemoveMedia:removedDiscs];
    }
    
    /*  Shutdown the query.
     */
    MDQueryStop(query);
    CFRelease(query);
    query = nil;
    mediaProcessed = 0;
}

- (NSMutableDictionary*) infoDictionaryForMedia:(MediaFile*)media
{
    NSAssert(media.mediaFileSource == self, @"This media doesn't belong to me.");
    NSMutableDictionary* mediaInfo = media.mediaInfo;
    
    NSMutableDictionary* info = [mediaInfo objectForKey:@"info"];
    if (!info) {
        NSString* pathToFile = [media pathToFile];
        if (!info) {
            info = [NSMutableDictionary dictionary];
        }
        [mediaInfo setObject:info forKey:@"info"];
        
        /*  Add a meta-dictionary if none exists.
         */
        NSMutableDictionary* meta = [info objectForKey:@"meta"];
        if (!meta) {
            [info setObject:meta = [NSMutableDictionary dictionary] forKey:@"meta"]; 
        }
        
        /*  Add a file-meta dictionary if none exists.
         */
        NSMutableDictionary* fileMeta = [meta objectForKey:@"file"];
        if (!fileMeta) {
            [meta setObject:fileMeta = [NSMutableDictionary dictionary] forKey:@"file"]; 
        }
        
        /*  All discs should have a title, even if it's just one that's been
         *  derived from the (possibly crappy) name in the filesystem.
         */
        [fileMeta setObject:[[[pathToFile lastPathComponent] stringByDeletingPathExtension] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]] forKey:@"title"];
    }
    
    return info;
}

- (void) setInfoDictionary:(NSMutableDictionary*)infoDictionary forMedia:(MediaFile*)media
{
    NSLog(@"I do nothing for this type of media");
}

- (NSData*) frontCoverForMedia:(MediaFile*)media
{
    NSAssert(media.mediaFileSource == self, @"This media doesn't belong to me.");
    NSLog(@"Do something eventually");
    return nil;
    //return [NSData dataWithContentsOfFile:[[media.pathToFile stringByAppendingPathComponent:@"QuickLook"] stringByAppendingPathComponent:@"FrontCover.png"]];
}

- (void) setFrontCover:(NSData*)frontCover forMedia:(MediaFile*)media
{
    NSAssert(media.mediaFileSource == self, @"This media doesn't belong to me.");    
#if 0
    NSString* pathToQuickLookFolder = [media.pathToFile stringByAppendingPathComponent:@"QuickLook"];
    NSFileManager* fileManager = [NSFileManager defaultManager];
    [fileManager createDirectoryAtPath:pathToQuickLookFolder attributes:nil];
    if ([fileManager fileExistsAtPath:pathToQuickLookFolder]) {
        [frontCover writeToFile:[pathToQuickLookFolder stringByAppendingPathComponent:@"FrontCover.png"] atomically:YES];
    }
#endif
    NSLog(@"Once implemented, set the icon");
}

- (void) reloadMedia:(MediaFile*)media
{
    NSAssert(media.mediaFileSource == self, @"This media doesn't belong to me.");
    NSMutableDictionary* mediaInfo = media.mediaInfo;
#if 0
    MDItemRef item = (MDItemRef)[mediaInfo objectForKey:@"item"];
    CFDictionaryRef meta = MDItemCopyAttributeList(
        item,
        @"com_discident_fingerprint",
        nil
    );
    [mediaInfo setObject:(id)meta forKey:@"meta"];
    CFRelease(meta);
#endif
    [mediaInfo removeObjectForKey:@"info"];
}

- (NSString*) fingerprintForMedia:(MediaFile*)media
{
    NSAssert(media.mediaFileSource == self, @"This media doesn't belong to me.");
    NSMutableDictionary* mediaInfo = media.mediaInfo;
    NSString* fingerprint = (NSString*)MDItemCopyAttribute((MDItemRef)[mediaInfo objectForKey:@"item"], kMDItemMultiplexNonDVDFingerprint);
    return [fingerprint autorelease];
}

- (NSString*) pathToFileForMedia:(MediaFile*)media
{
    NSAssert(media.mediaFileSource == self, @"This media doesn't belong to me.");
    NSMutableDictionary* mediaInfo = media.mediaInfo;
    NSString* pathToFile = (NSString*)MDItemCopyAttribute((MDItemRef)[mediaInfo objectForKey:@"item"], kMDItemPath);
    return [pathToFile autorelease];
}

- (NSString*) typeForMedia:(MediaFile*)media
{
    NSAssert(media.mediaFileSource == self, @"This media doesn't belong to me.");
    NSMutableDictionary* mediaInfo = media.mediaInfo;
    NSString* itemType = (NSString*)MDItemCopyAttribute((MDItemRef)[mediaInfo objectForKey:@"item"], kMDItemContentType);
    if (!itemType) {
        itemType = [media.pathToFile pathExtension];
    }
    NSLog(@"Item type: %@", itemType);
    return [itemType autorelease];
}

- (void) _fireDidAddMedia:(NSArray*)media
{
    if ([NSThread currentThread] == [NSThread mainThread]) {
        @try {
            [delegate mediaFileSource:self didAddMedia:media];
        } @catch (id exception) {
            NSLog(@"%s: %@", __PRETTY_FUNCTION__, exception);
        }
    } else {
        [self performSelectorOnMainThread:@selector(_fireDidAddMedia:) withObject:media waitUntilDone:NO];
    }
}

- (void) _fireDidUpdateMedia:(NSArray*)media
{
    if ([NSThread currentThread] == [NSThread mainThread]) {
        @try {
            [delegate mediaFileSource:self didUpdateMedia:media];
        } @catch (id exception) {
            NSLog(@"%s: %@", __PRETTY_FUNCTION__, exception);
        }
    } else {
        [self performSelectorOnMainThread:@selector(_fireDidUpdateMedia:) withObject:media waitUntilDone:NO];
    }
}

- (void) _fireDidRemoveMedia:(NSArray*)media
{
    if ([NSThread currentThread] == [NSThread mainThread]) {
        @try {
            [delegate mediaFileSource:self didRemoveMedia:media];
        } @catch (id exception) {
            NSLog(@"%s: %@", __PRETTY_FUNCTION__, [exception callStackReturnAddresses]);
        }
    } else {
        [self performSelectorOnMainThread:@selector(_fireDidRemoveMedia:) withObject:media waitUntilDone:NO];
    }
}

- (void) _fireDidFinishQuery
{
    if ([NSThread currentThread] == [NSThread mainThread]) {
        @try {
            [delegate mediaFileSource:self didFinishQuery:YES];
        } @catch (id exception) {
            NSLog(@"%s: %@", __PRETTY_FUNCTION__, [exception callStackReturnAddresses]);
        }
    } else {
        [self performSelectorOnMainThread:@selector(_fireDidFinishQuery) withObject:nil waitUntilDone:NO];
    }
}

- (void) _queryDidUpdate:(NSNotification*)notification
{
    NSDictionary* info = [notification userInfo];
    
    NSArray* removedDiscs = [info objectForKey:(id)kMDQueryUpdateRemovedItems];
    if (removedDiscs) {
        [self _fireDidRemoveMedia:removedDiscs];
    }
    
    NSArray* changedDiscs = [info objectForKey:(id)kMDQueryUpdateChangedItems];
    if (changedDiscs) {
        [self _fireDidUpdateMedia:changedDiscs];
    }
    
    if ([[notification name] isEqualTo:(id)kMDQueryProgressNotification]) {
        int imax = MDQueryGetResultCount(query);
        NSMutableArray* addedDiscs = [NSMutableArray array];
        int i;
        for (i = mediaProcessed; i < imax; i++) {
            MediaFile* file = (MediaFile*)MDQueryGetResultAtIndex(query, i);
            if (file) {
                [addedDiscs addObject:file];                
            }
        }
        
        if ([addedDiscs count]) {
            [self _fireDidAddMedia:addedDiscs];
        }
        mediaProcessed = imax;
    } else if ([[notification name] isEqualTo:(id)kMDQueryDidFinishNotification]) {
        //NSLog(@"finished");
    } else {
        NSArray* addedDiscs = [info objectForKey:(id)kMDQueryUpdateAddedItems];
        if (addedDiscs) {
            [self _fireDidAddMedia:addedDiscs];
        }
    }
}

- (void) _queryDidFinish:(NSNotification*)notification
{
    // Send it to did update
    [self _queryDidUpdate:notification];
    [self _fireDidFinishQuery];
}

@end
