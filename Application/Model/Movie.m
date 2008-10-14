#import "Movie.h"

@implementation Movie

@dynamic aspectRatio;
@dynamic genre;
@dynamic gtin;
@dynamic productionYear;
@dynamic regionCode;
@dynamic releaseDate;
@dynamic review;
@dynamic runningTime;
@dynamic studio;
@dynamic synopsis;
@dynamic theatricalReleaseDate;
@dynamic title;
@dynamic rating;
@dynamic frontCover;

@dynamic allDiscs;

#if 0
static NSMutableDictionary* frontCoversbyObjectID = nil;

- (void) setFrontCover:(id)frontCover
{
    [self willChangeValueForKey:@"frontCover"];
    if (!frontCoversbyObjectID) {
        frontCoversbyObjectID = [[NSMutableDictionary alloc] init];
    }
    if (frontCover) {
        [frontCoversbyObjectID setObject:frontCover forKey:self.objectID];
    } else {
        [frontCoversbyObjectID removeObjectForKey:self.objectID];
    }
    [self didChangeValueForKey:@"frontCover"];
}

- (id) frontCover
{
    return [frontCoversbyObjectID objectForKey:self.objectID];
}
#endif

@end