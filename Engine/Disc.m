#import "Disc.h"
#import "Media.h"

#pragma mark -
@implementation Disc

- (id) initWithMedia:(Media*)_media
{
	if (self = [super init]) {
		allMedia = [[NSMutableArray alloc] initWithObjects:_media, nil];
		fingerprint = [[_media fingerprint] retain];
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

- (void) addMedia:(Media*)media
{
    [allMedia addObject:media];
    [media setDisc:self];
}

- (NSString*) contentType
{
	return [[allMedia objectAtIndex:0] contentType];
}

- (NSString*) fingerprint
{
	return fingerprint;
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

- (void) removeMedia:(Media*)media
{
    NSAssert([media disc] == self, @"");
    [media setDisc:nil];
    [allMedia removeObject:media];
}

@end
