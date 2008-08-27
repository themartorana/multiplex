#import "Movie.h"
#import "Disc.h"

#pragma mark -
@implementation Movie

- (id) initWithDisc:(Disc*)_disc
{
	if (self = [super init]) {
		discs = [[NSMutableArray alloc] initWithObjects:_disc, nil];
		fingerprint = [[_disc fingerprint] retain];
        [_disc setMovie:self];
	}
	return self;
}

- (void) dealloc
{
    [discs release];
	[fingerprint release];
	[super dealloc];
}

- (void) addDisc:(Disc*)disc
{
    [discs addObject:disc];
    [disc setMovie:self];
}

- (NSString*) contentType
{
	return [[discs objectAtIndex:0] contentType];
}

- (NSString*) fingerprint
{
	return fingerprint;
}

- (BOOL) hasDisc
{
	return [discs count] > 0;
}

- (NSString*) pathToFile
{
	return [[discs objectAtIndex:0] pathToFile];
}

- (BOOL) isPhysicalMedia
{
    return [[discs objectAtIndex:0] isPhysicalMedia];
}

- (void) removeDisc:(Disc*)disc
{
    NSAssert([disc movie] == self, @"");
    [disc setMovie:nil];
    [discs removeObject:disc];
}

@end
