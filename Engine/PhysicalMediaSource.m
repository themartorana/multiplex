#import "PhysicalMediaSource.h"
#import "DiscIdentQuery.h"
#import <IOKit/IOKitLib.h>
#import <IOKit/storage/IOMedia.h>
#import <IOKit/storage/IODVDMedia.h>
#import <sys/mount.h>

#import "NSImage+DmgCtrl.h"


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
        [delegate mediaSource:self didRemoveMedia:[mediaByDeviceName allValues]];
        [mediaByDeviceName removeAllObjects];
    }

    started = NO;
}

- (NSMutableDictionary*) infoDictionaryForMedia:(Media*)media
{
    NSAssert(media.mediaSource == self, @"This media doesn't belong to me.");
    
    /*  Attempt to load the Info.json from the filesystem.  If this fails,
     *  we create a new, empty dictionary containing just the fingerprint.
     */
    NSMutableDictionary* info = [NSMutableDictionary dictionary];
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
    
    return info;
}

- (void) setInfoDictionary:(NSMutableDictionary*)infoDictionary forMedia:(Media*)media
{
    NSAssert(media.mediaSource == self, @"This media doesn't belong to me.");
}

- (void) setFrontCover:(NSImage*)coverArt forMedia:(Media*)media
{
    NSAssert(media.mediaSource == self, @"This media doesn't belong to me.");
}

- (void) _volumeDidMount:(NSNotification*)notification
{
    [self _tryToUseMountPoint:[[notification userInfo] objectForKey:@"NSDevicePath"]];
}

- (void) _volumeDidUnmount:(NSNotification*)notification
{
    NSString* deviceName = [self _deviceNameForMountPoint:[[notification userInfo] objectForKey:@"NSDevicePath"]];
    Media* disc = [mediaByDeviceName objectForKey:deviceName];
    if (disc) {
        [delegate mediaSource:self didRemoveMedia:[NSArray arrayWithObject:disc]];
        [mediaByDeviceName removeObjectForKey:deviceName];
    }
}

- (void) _tryToUseMountPoint:(NSString*)mountPoint
{
    NSString* deviceName = [self _deviceNameForMountPoint:mountPoint];
    if ([self _isNamedDeviceDVD:deviceName]) {
        NSString* fingerprint = [mountPoint discidentFingerprintForPath];
        if (fingerprint) {
            Media* disc = [[Media alloc] initWithMediaSource:self physicalMedia:fingerprint atPath:mountPoint];
            [delegate mediaSource:self didAddMedia:[NSArray arrayWithObject:disc]];
            [mediaByDeviceName setObject:disc forKey:deviceName];
            [disc release];
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
