#import "Movie.h"
#import "Disc.h"

@implementation Movie

@dynamic aspectRatio;
@dynamic availableDiscCount;
@dynamic boxArt;
@dynamic genre;
@dynamic gtin;
@dynamic metadataAcceptedDate;
@dynamic productionYear;
@dynamic rating;
@dynamic regionCode;
@dynamic releaseDate;
@dynamic review;
@dynamic runningTime;
@dynamic starRating;
@dynamic studio;
@dynamic synopsis;
@dynamic theatricalReleaseDate;
@dynamic title;
@dynamic format;

@dynamic allDiscs;
@dynamic allParticipants;
@dynamic allMovieURLs;

- (int) localMediaCount
{
    int returnCount = 0;
    
    for (Disc* d in self.allDiscs) {
        returnCount += [d.localMediaCount intValue];
    }
    
    return returnCount;
}

- (NSArray*) discsInOrder {
    NSSortDescriptor* sort = [[NSSortDescriptor alloc] initWithKey:@"number" ascending:YES];
    return [[self.allDiscs allObjects] sortedArrayUsingDescriptors:[NSArray arrayWithObject:sort]];
}

@end