#import "MovieLayer.h"
#import "Movie.h"
#import "Disc.h"
#import "Media.h"

@implementation MovieLayer

@synthesize movie;

- (void) setMovie:(Movie*)_movie {
    movie = _movie;
    
    BOOL fullBreak = false;
    
    // Look for the first instance of a cover
    NSArray* discs = [movie.allDiscs allObjects];

    for (Disc* disc in discs) {
        NSArray* discMedia = [disc.allMedia allObjects];

        for (Media* media in discMedia) {
            if (media.url && [media.url length] > 0) {
                
                NSString* url = [[media.url stringByAppendingPathComponent:@"QuickLook"] stringByAppendingPathComponent:@"FrontCover.png"];
                NSLog(@"%@", url);
            }
        }
    }
    
}

@end
