#import "Item.h"
#import "JSONKit/JSONKit.h"
//#import "Debug.h"

const CFStringRef kMDItemDiscIdentFingerprint	= (CFStringRef)@"com_discident_fingerprint";

extern void MDItemSetAttribute(MDItemRef, CFStringRef, CFTypeRef);
extern void MDItemRemoveAttribute(MDItemRef, CFStringRef);

@implementation Item

@synthesize movie;

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
	}
	return self;
}

- (void) dealloc
{
	CFRelease(itemRef);
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
