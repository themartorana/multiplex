#import "Disc.h"
#import "Media.h"

#pragma mark -
@implementation Disc
@dynamic allMedia;
@synthesize infoDictionary;
@synthesize fingerprint;

- (id) initWithFingerprint:(NSString*)_fingerprint media:(Media*)_media
{
    NSAssert(_fingerprint, @"fingerprint cannot be nil.");
    NSAssert(_media, @"media cannot be nil.");
    NSAssert([_fingerprint isEqualToString:[_media fingerprint]], @"Fingerprints do not match.");
	if (self = [super init]) {
		allMedia = [[NSMutableArray alloc] initWithObjects:_media, nil];
		fingerprint = [_fingerprint retain];
        [_media setDisc:self];
	}
	return self;
}

- (void) dealloc
{
    [allMedia release];
	[fingerprint release];
	[super dealloc];
}

- (NSString*) contentType
{
	return [[allMedia objectAtIndex:0] contentType];
}

- (BOOL) hasDisc
{
	return [allMedia count] > 0;
}

- (NSString*) pathToFile
{
	return [[allMedia objectAtIndex:0] pathToFile];
}

- (BOOL) isPhysicalMedia
{
    return [[allMedia objectAtIndex:0] isPhysicalMedia];
}

- (void) addMedia:(Media*)media
{
    NSAssert([media disc] == nil, @"");
    [allMedia addObject:media];
    [media setDisc:self];
}

- (void) removeMedia:(Media*)media
{
    NSAssert([media disc] == self, @"");
    [media setDisc:nil];
    [allMedia removeObject:media];
}

- (NSArray*) allMedia
{
    return [[allMedia retain] autorelease];
}

- (void) setInfoDictionary:(NSMutableDictionary*)_infoDictionary
{
    if (infoDictionary != _infoDictionary) {
        [infoDictionary release];
        infoDictionary = [_infoDictionary retain];
        for (Media* media in allMedia) {
            media.infoDictionary = _infoDictionary;
        }
    }
}

@end
