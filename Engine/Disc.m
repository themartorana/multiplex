#import "Disc.h"
#import "JSONKit/JSONKit.h"
//#import "Debug.h"

const CFStringRef kMDItemDiscIdentFingerprint	= (CFStringRef)@"com_discident_fingerprint";

extern void MDItemSetAttribute(MDItemRef, CFStringRef, CFTypeRef);
extern void MDItemRemoveAttribute(MDItemRef, CFStringRef);

@implementation Disc

@synthesize movie;
@synthesize isPhysicalMedia;

static NSArray* allKeys;

+ (void) initialize
{
	allKeys = [[NSArray arrayWithObjects:
		(id)kMDItemContentType,
		(id)kMDItemDiscIdentFingerprint,
		(id)kMDItemFSSize,
		(id)kMDItemPath,
		nil
	] retain];
}

- (id) initWithMDItemRef:(MDItemRef)_itemRef
{
	if (self = [super init]) {
		itemRef = (MDItemRef)CFRetain(_itemRef);
		[self reload];
        
        isPhysicalMedia = NO;
	}
	return self;
}

- (id) initWithPhysicalMedia:(NSString*)fingerprint atPath:(NSString*)pathToMedia
{
    if (self = [super init]) {
        info = [[NSDictionary alloc] initWithObjectsAndKeys:
            @"public.dvdmedia", (id)kMDItemContentType,
            fingerprint, (id)kMDItemDiscIdentFingerprint,
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

- (Movie*) movie
{
	return movie;
}

- (NSString*) contentType
{
	return [info objectForKey:(id)kMDItemContentType];
}

- (NSString*) fingerprint
{
	return [info objectForKey:(id)kMDItemDiscIdentFingerprint];
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
	[info autorelease];
	info = [(NSDictionary*)MDItemCopyAttributes(itemRef, (CFArrayRef)allKeys) retain];
}

@end
