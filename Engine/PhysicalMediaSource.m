#import "PhysicalMediaSource.h"
#import "Item.h"
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
- (void) _volumeWillUnmount:(NSNotification*)notification;
@end

#pragma mark -

@implementation PhysicalMediaSource
@synthesize delegate;

- (id) init
{
    if (self = [super init]) {
        itemsByDeviceName = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void) dealloc
{
    [itemsByDeviceName release];
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
    [notificationCenter addObserver:self selector:@selector(_volumeWillUnmount:) name:NSWorkspaceWillUnmountNotification object:nil];
}

- (void) stop
{
    /*  Shutdown our mount/unmount notification handlers.
     */
    NSNotificationCenter* notificationCenter = [[NSWorkspace sharedWorkspace] notificationCenter];
    [notificationCenter removeObserver:self];


    /*  Notify our delegate that all of the items that we're currently tracking
     *  will no longer be available.
     */
    if ([itemsByDeviceName count]) {
        [delegate mediaSource:self didRemoveItems:[itemsByDeviceName allValues]];
        [itemsByDeviceName removeAllObjects];
    }

    started = NO;
}

- (void) _volumeDidMount:(NSNotification*)notification
{
    [self _tryToUseMountPoint:[[notification userInfo] objectForKey:@"NSDevicePath"]];
}

- (void) _volumeWillUnmount:(NSNotification*)notification
{
    NSString* deviceName = [self _deviceNameForMountPoint:[[notification userInfo] objectForKey:@"NSDevicePath"]];
    Item* item = [itemsByDeviceName objectForKey:deviceName];
    if (item) {
        [delegate mediaSource:self didRemoveItems:[NSArray arrayWithObject:item]];
        [itemsByDeviceName removeObjectForKey:deviceName];
    }
}

- (void) _tryToUseMountPoint:(NSString*)mountPoint
{
    NSString* deviceName = [self _deviceNameForMountPoint:mountPoint];
    if ([self _isNamedDeviceDVD:deviceName]) {
        NSString* fingerprint = [mountPoint discidentFingerprintForPath];
        if (fingerprint) {
            Item* item = [[Item alloc] initWithPhysicalMedia:fingerprint atPath:mountPoint];
            [delegate mediaSource:self didAddItems:[NSArray arrayWithObject:item]];
            [itemsByDeviceName setObject:item forKey:deviceName];
            [item release];
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
