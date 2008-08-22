#import "Movie.h"
#import "Item.h"

#pragma mark -
@implementation Movie

@synthesize listenForLoopback;

- (id) initWithItem:(Item*)_item
{
	if (self = [super init]) {
		items = [[NSMutableArray alloc] initWithObjects:_item, nil];
		fingerprint = [[_item fingerprint] retain];
        [_item setMovie:self];
        
        listenForLoopback = NO;
	}
	return self;
}

- (void) dealloc
{
    [items release];
	[fingerprint release];
	[super dealloc];
}

- (void) addItem:(Item*)item
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
	return items != nil;
}

- (NSString*) pathToFile
{
	return [[items objectAtIndex:0] pathToFile];
}

- (BOOL) isPhysicalMedia
{
    return [[items objectAtIndex:0] isPhysicalMedia];
}

- (void) removeItem:(Item*)item
{
    NSAssert([item movie] == self, @"");
    [item setMovie:nil];
    [items removeObject:item];
}

@end
