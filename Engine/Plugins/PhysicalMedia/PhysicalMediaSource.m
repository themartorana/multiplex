#import "PhysicalMediaSource.h"
#import <DiscIdentKit/DiscIdentKit.h>
#import <IOKit/IOKitLib.h>
#import <IOKit/storage/IOMedia.h>
#import <IOKit/storage/IODVDMedia.h>
#import <sys/mount.h>

#import <Toolkit/Toolkit.h>
#import <JSONKit/JSONKit.h>

@interface NSApplication (Extras)

- (NSString*) pathToUserApplicationSupportFolder;

@end

@implementation NSApplication (Extras)

- (NSString*) pathToUserApplicationSupportFolder
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    if (![paths count]) {
        return nil;
    }
    return [paths objectAtIndex:0]; 
}

@end

@interface PhysicalMediaSource (Private)
- (NSString*) _deviceNameForMountPoint:(NSString*)mountPoint;
- (BOOL) _isNamedDeviceDVD:(NSString*)deviceName;
- (void) _tryToUseMountPoint:(NSString*)mountPoint;
- (void) _volumeDidMount:(NSNotification*)notification;
- (void) _volumeDidUnmount:(NSNotification*)notification;
@end

#pragma mark -

@implementation PhysicalMediaSource
@synthesize delegate;

- (NSString*) _pathToInfoFolder 
{
    return [[[NSApp pathToUserApplicationSupportFolder] stringByAppendingPathComponent:@"Multiplex"] stringByAppendingPathComponent:@"Info"];
}

- (NSString*) _pathToInfoFileForMedia:(MediaFile*)media 
{
    return [[self _pathToInfoFolder] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.json", [self fingerprintForMedia:media]]];
}

- (NSString*) _pathToFrontCoverForMedia:(MediaFile*)media 
{
    return [[self _pathToInfoFolder] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@-FrontCover.png", [self fingerprintForMedia:media]]];
}

- (id) init
{
    if (self = [super init]) {
        mediaByDeviceName = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void) dealloc
{
    [mediaByDeviceName release];
    [super dealloc];
}

- (void) start
{
    NSAssert(!started, @"PhysicalMediaSource already started.");
    started = YES;
    
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSError* error = nil;
    [fileManager createDirectoryAtPath:[self _pathToInfoFolder] withIntermediateDirectories:YES attributes:nil error:&error];
    
    /*  Pickup any media that's already mounted.
     */
    for (NSString* mountPoint in [[NSWorkspace sharedWorkspace] mountedRemovableMedia]) {
        [self _tryToUseMountPoint:mountPoint];
    }
    
    /*  Make sure we get notified about any future mounts/unmounts.
     */
    NSNotificationCenter* notificationCenter = [[NSWorkspace sharedWorkspace] notificationCenter];
    [notificationCenter addObserver:self selector:@selector(_volumeDidMount:) name:NSWorkspaceDidMountNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(_volumeDidUnmount:) name:NSWorkspaceWillUnmountNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(_volumeDidUnmount:) name:NSWorkspaceDidUnmountNotification object:nil];
}

- (void) stop
{
    /*  Shutdown our mount/unmount notification handlers.
     */
    NSNotificationCenter* notificationCenter = [[NSWorkspace sharedWorkspace] notificationCenter];
    [notificationCenter removeObserver:self];


    /*  Notify our delegate that all of the discs that we're currently tracking
     *  will no longer be available.
     */
    if ([mediaByDeviceName count]) {
        [delegate mediaFileSource:self didRemoveMedia:[mediaByDeviceName allValues]];
        [mediaByDeviceName removeAllObjects];
    }

    started = NO;
}

- (NSMutableDictionary*) infoDictionaryForMedia:(MediaFile*)media
{
    NSAssert(media.mediaFileSource == self, @"This media doesn't belong to me.");
    NSMutableDictionary* mediaInfo = media.mediaInfo;
    
    NSString *pathToInfoFile = [self _pathToInfoFileForMedia: media];
    NSMutableDictionary* info = [NSMutableDictionary dictionaryWithJSON:[NSString stringWithContentsOfFile:pathToInfoFile]];
    if (!info) {
        info = [NSMutableDictionary dictionary];

        [mediaInfo setObject:info = [NSMutableDictionary dictionary] forKey:@"info"];

        NSMutableDictionary* meta = [NSMutableDictionary dictionary];
        NSMutableDictionary* fileMeta = [NSMutableDictionary dictionary];
        
        /*  Add a meta-dictionary if none exists.
         */
        [info setObject:meta forKey:@"meta"]; 
        
        /*  Add a file-meta dictionary if none exists.
         */
        [meta setObject:fileMeta forKey:@"file"]; 
        
        /*  All discs should have a title, even if it's just one that's been
         *  derived from the (possibly crappy) name in the filesystem.
         */
        [fileMeta setObject:[[[[media pathToFile] lastPathComponent] stringByDeletingPathExtension] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]] forKey:@"title"];
    }
    
    return info;
}

- (void) setInfoDictionary:(NSMutableDictionary*)infoDictionary forMedia:(MediaFile*)media
{
    NSAssert(media.mediaFileSource == self, @"This media doesn't belong to me.");
    NSMutableDictionary* mediaInfo = media.mediaInfo;
    [mediaInfo setObject:infoDictionary forKey:@"info"];

    NSString *pathToInfoFile = [self _pathToInfoFileForMedia: media];
    NSData* dataToWrite = [NSData dataWithObjectAsJSON:infoDictionary];
    NSData* dataThatsThere = [NSData dataWithContentsOfFile:pathToInfoFile];
    if (([dataToWrite length] != [dataThatsThere length]) || ![dataToWrite isEqualToData:dataThatsThere]) {
        [dataToWrite writeToFile:pathToInfoFile atomically:YES];
    }
}

- (NSData*) frontCoverForMedia:(MediaFile*)media
{
    NSAssert(media.mediaFileSource == self, @"This media doesn't belong to me.");
    return [NSData dataWithContentsOfFile:[self _pathToFrontCoverForMedia: media]];
}

- (void) setFrontCover:(NSData*)frontCover forMedia:(MediaFile*)media
{
    NSAssert(media.mediaFileSource == self, @"This media doesn't belong to me.");
    [frontCover writeToFile:[self _pathToFrontCoverForMedia: media] atomically:YES];
}

- (void) reloadMedia:(MediaFile*)media
{
    NSAssert(media.mediaFileSource == self, @"This media doesn't belong to me.");
    /* Ignored */
}

- (NSString*) pathToFileForMedia:(MediaFile*)media
{
    NSAssert(media.mediaFileSource == self, @"This media doesn't belong to me.");
    NSMutableDictionary* mediaInfo = media.mediaInfo;
    return [mediaInfo objectForKey:@"mountPoint"];
}

- (NSString*) fingerprintForMedia:(MediaFile*)media
{
    NSAssert(media.mediaFileSource == self, @"This media doesn't belong to me.");
    NSMutableDictionary* mediaInfo = media.mediaInfo;
    return [mediaInfo objectForKey:@"fingerprint"];
}

- (NSString*) typeForMedia:(MediaFile*)media
{
    NSAssert(media.mediaFileSource == self, @"This media doesn't belong to me.");
    return @"public.dvdmedia";
}

- (void) _fireDidAddMedia:(NSArray*)media
{
    if ([NSThread currentThread] == [NSThread mainThread]) {
        @try {
            [delegate mediaFileSource:self didAddMedia:media];
        } @catch (id exception) {
            /* IGNORED */
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
            /* IGNORED */
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
            /* IGNORED */
        }
    } else {
        [self performSelectorOnMainThread:@selector(_fireDidRemoveMedia:) withObject:media waitUntilDone:NO];
    }
}

- (void) _volumeDidMount:(NSNotification*)notification
{
    [self _tryToUseMountPoint:[[notification userInfo] objectForKey:@"NSDevicePath"]];
}

- (void) _volumeDidUnmount:(NSNotification*)notification
{
    NSString* deviceName = [self _deviceNameForMountPoint:[[notification userInfo] objectForKey:@"NSDevicePath"]];
    MediaFile* media = [mediaByDeviceName objectForKey:deviceName];
    if (media) {
        [self _fireDidRemoveMedia:[NSArray arrayWithObject:media]];
        [mediaByDeviceName removeObjectForKey:deviceName];
    }
}

- (void) _tryToUseMountPoint:(NSString*)mountPoint
{
    NSString* deviceName = [self _deviceNameForMountPoint:mountPoint];
    if ([self _isNamedDeviceDVD:deviceName]) {
        NSString* fingerprint = [mountPoint stringByComputingDiscIdentFingerprintForDiscAtPath];
        if (fingerprint) {
            MediaFile* media = [[MediaFile alloc] initWithMediaSource:self mediaInfo:[[NSMutableDictionary alloc] initWithObjectsAndKeys:fingerprint, @"fingerprint", mountPoint, @"mountPoint", nil]];
            [self _fireDidAddMedia:[NSArray arrayWithObject:media]];
            [mediaByDeviceName setObject:media forKey:deviceName];
            [media release];
        }
    }
}

- (NSString*) _deviceNameForMountPoint:(NSString*)mountPoint
{
    struct statfs s;
    if (0 != statfs([mountPoint fileSystemRepresentation], &s)) {
        return nil;
    }
    NSString* name = [[[NSString alloc] initWithUTF8String:s.f_mntfromname] autorelease];
    if ([name hasPrefix:@"/dev/"]) {
        name = [name substringFromIndex:5];
    }
    return name;
}

- (BOOL) _isNamedDeviceDVD:(NSString*)deviceName
{
    BOOL result = NO;
    CFMutableDictionaryRef m;
    if (m = IOBSDNameMatching(kIOMasterPortDefault, 0, [deviceName UTF8String])) {
        io_service_t service = IOServiceGetMatchingService(kIOMasterPortDefault, m);   
        if (service) {
            io_iterator_t iterator;
            if (KERN_SUCCESS == IORegistryEntryCreateIterator( 
                service,
                kIOServicePlane,
                kIORegistryIterateRecursively | kIORegistryIterateParents,
                &iterator 
            )) {
                if (iterator) {
                    IOObjectRetain(service);
                    do {
                        result = IOObjectConformsTo(service, kIODVDMediaClass);
                        IOObjectRelease(service);
                    } while (!result && (service = IOIteratorNext(iterator)));
                    IOObjectRelease(iterator);
                }
            }
            IOObjectRelease(service);
        }
    }
    return result;
}

@end
