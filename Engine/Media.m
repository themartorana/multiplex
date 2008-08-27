#import "Media.h"
#import "JSONKit/JSONKit.h"
#import "MediaSource.h"

const CFStringRef kMDDiscDiscIdentFingerprint	= (CFStringRef)@"com_discident_fingerprint";

extern void MDItemSetAttribute(MDItemRef, CFStringRef, CFTypeRef);
extern void MDItemRemoveAttribute(MDItemRef, CFStringRef);

@implementation Media

@synthesize disc;
@synthesize isPhysicalMedia;
@synthesize mediaSource;

static NSArray* allKeys;

+ (void) initialize
{
	allKeys = [[NSArray arrayWithObjects:
		(id)kMDItemContentType,
		(id)kMDDiscDiscIdentFingerprint,
		(id)kMDItemFSSize,
		(id)kMDItemPath,
		nil
	] retain];
}

- (id) initWithMediaSource:(id<MediaSource>)_mediaSource MDItemRef:(MDItemRef)_itemRef
{
	if (self = [super init]) {
        mediaSource = _mediaSource; // NOT RETAINED.
		itemRef = (MDItemRef)CFRetain(_itemRef);
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
        info = [(NSDictionary*)MDItemCopyAttributes(itemRef, (CFArrayRef)allKeys) retain];
    }
}

@end
