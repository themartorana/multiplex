#import "PhysicalMediaSource.h"
#import "Disc.h"
#import "NSString+DiscIdent.h"
#import <IOKit/IOKitLib.h>
#import <IOKit/storage/IOMedia.h>
#import <IOKit/storage/IODVDMedia.h>
#import <sys/mount.h>

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
        discsByDeviceName = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void) dealloc
{
    [discsByDeviceName release];
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
    if ([discsByDeviceName count]) {
        [delegate mediaSource:self didRemoveDiscs:[discsByDeviceName allValues]];
        [discsByDeviceName removeAllObjects];
    }

    started = NO;
}

- (void) _volumeDidMount:(NSNotification*)notification
{
    [self _tryToUseMountPoint:[[notification userInfo] objectForKey:@"NSDevicePath"]];
}

- (void) _volumeDidUnmount:(NSNotification*)notification
{
    NSString* deviceName = [self _deviceNameForMountPoint:[[notification userInfo] objectForKey:@"NSDevicePath"]];
    Disc* disc = [discsByDeviceName objectForKey:deviceName];
    if (disc) {
        [delegate mediaSource:self didRemoveDiscs:[NSArray arrayWithObject:disc]];
        [discsByDeviceName removeObjectForKey:deviceName];
    }
}

- (void) _tryToUseMountPoint:(NSString*)mountPoint
{
    NSString* deviceName = [self _deviceNameForMountPoint:mountPoint];
    if ([self _isNamedDeviceDVD:deviceName]) {
        NSString* fingerprint = [mountPoint discidentFingerprintForPath];
        if (fingerprint) {
            Disc* disc = [[Disc alloc] initWithPhysicalMedia:fingerprint atPath:mountPoint];
            [delegate mediaSource:self didAddDiscs:[NSArray arrayWithObject:disc]];
            [discsByDeviceName setObject:disc forKey:deviceName];
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
