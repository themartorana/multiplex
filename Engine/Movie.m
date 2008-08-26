#import "Movie.h"
#import "Disc.h"

#pragma mark -
@implementation Movie

- (id) initWithItem:(Disc*)_item
{
	if (self = [super init]) {
		items = [[NSMutableArray alloc] initWithObjects:_item, nil];
		fingerprint = [[_item fingerprint] retain];
        [_item setMovie:self];
	}
	return self;
}

- (void) dealloc
{
    [items release];
	[fingerprint release];
	[super dealloc];
}

- (void) addItem:(Disc*)item
{
    [items addObject:item];
    [item setMovie:self];
}

- (NSString*) contentType
{
	return [[items objectAtIndex:0] contentType];
}

- (NSString*) fingerprint
{
	return fingerprint;
}

- (BOOL) hasItem
{
	return [items count] > 0;
}

- (NSString*) pathToFile
{
	return [[items objectAtIndex:0] pathToFile];
}

- (BOOL) isPhysicalMedia
{
    return [[items objectAtIndex:0] isPhysicalMedia];
}

- (void) removeItem:(Disc*)item
{
    NSAssert([item movie] == self, @"");
    [item setMovie:nil];
    [items removeObject:item];
}

@end
