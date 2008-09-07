#import "Media.h"
#import "JSONKit/JSONKit.h"
#import "MediaSource.h"
#import <libkern/OSAtomic.h>

const CFStringRef kMDDiscDiscIdentFingerprint = CFSTR("com_discident_fingerprint");

extern void MDItemSetAttribute(MDItemRef, CFStringRef, CFTypeRef);
extern void MDItemRemoveAttribute(MDItemRef, CFStringRef);

@implementation Media

@synthesize disc;
@synthesize url;
@synthesize isPhysicalMedia;
@synthesize mediaSource;

- (id) initWithMediaSource:(id<MediaSource>)_mediaSource MDItemRef:(MDItemRef)_itemRef
{
	if (self = [super init]) {
        mediaSource = _mediaSource; // NOT RETAINED.
		itemRef = (MDItemRef)CFRetain(_itemRef);
        info = nil;
		[self reload];
        isPhysicalMedia = NO;
	}
	return self;
}

- (id) initWithMediaSource:(id<MediaSource>)_mediaSource physicalMedia:(NSString*)fingerprint atPath:(NSString*)pathToMedia
{
    if (self = [super init]) {
        mediaSource = _mediaSource; // NOT RETAINED.
        info = [[NSDictionary alloc] initWithObjectsAndKeys:
            @"public.dvdmedia", (id)kMDItemContentType,
            fingerprint, (id)kMDDiscDiscIdentFingerprint,
            pathToMedia, (id)kMDItemPath, 
            nil
        ];
        isPhysicalMedia = YES;
    }
    return self;
}

- (void) dealloc
{
    if (itemRef) {
        CFRelease(itemRef);
	}
    [info release];
	[super dealloc];
}

- (Disc*) disc
{
	return disc;
}

- (NSString*) contentType
{
	return [info objectForKey:(id)kMDItemContentType];
}

- (NSString*) fingerprint
{
	return [info objectForKey:(id)kMDDiscDiscIdentFingerprint];
}

- (NSString*) pathToFile
{
	return [info objectForKey:(id)kMDItemPath];
}

- (size_t) size
{
	return [[info objectForKey:(id)kMDItemFSSize] intValue];
}

- (void) reload
{
    if (!isPhysicalMedia) {
        [info autorelease];
        info = (NSDictionary*)MDItemCopyAttributeList(
            itemRef, 
            kMDItemContentType,
            kMDDiscDiscIdentFingerprint,
            kMDItemFSSize,
            kMDItemPath,
            nil
        );
    }
}

- (NSMutableDictionary*) infoDictionary
{
    NSAssert(mediaSource, @"No mediaSource?");
    return [mediaSource infoDictionaryForMedia:self];
}

- (void) setInfoDictionary:(NSMutableDictionary*)infoDictionary
{
    NSAssert(mediaSource, @"No mediaSource?");
    [mediaSource setInfoDictionary:infoDictionary forMedia:self];
}

@end
