#import "Disc.h"
#import "Movie.h"

@implementation Disc

+ (BOOL) isSelectorExcludedFromWebScript:(SEL)selector {
    const char* sName = sel_getName(selector);
    NSString* selectorName = [[[NSString alloc] initWithCString:sName] autorelease];
    /*
    if ([selectorName rangeOfString:@"set"].location == 0) {
        NSLog(@"Denied permission to %@", selectorName);
        return YES;
    }
    */
    NSLog(@"Granted permission for %@", selectorName);
    return NO;
}


@dynamic boxArt;
@dynamic movie;
@dynamic fingerprint;
@dynamic number;
@dynamic side;
@dynamic synopsis;
@dynamic discTitle;
@dynamic availableMediaCount;
@dynamic localMediaCount;

@dynamic allMedia;

- (void) setMovie:(Movie*)_movie
{
    BOOL isAvailable = 0 < [[self primitiveValueForKey:@"availableDiscCount"] intValue];
    Movie* movie = [self primitiveValueForKey:@"movie"];
    if (movie != _movie) {
        [super willChangeValueForKey:@"movie"];
        [self setPrimitiveValue:_movie forKey:@"movie"];
        if (isAvailable) {
            if (movie) {
                movie.availableDiscCount = [NSNumber numberWithInt:[movie.availableDiscCount intValue] - 1];
            }
            if (_movie) {
                _movie.availableDiscCount = [NSNumber numberWithInt:[_movie.availableDiscCount intValue] + 1];
            }
        }
        [super didChangeValueForKey:@"movie"];
    }
}

- (void) setAvailableMediaCount:(NSNumber*)_availableMediaCount
{
    [super willChangeValueForKey:@"availableDiscCount"];
    int oldValue = [[self primitiveValueForKey:@"availableDiscCount"] intValue];
    int newValue = [_availableMediaCount intValue];
    Movie* movie = [self primitiveValueForKey:@"movie"];
    [self setPrimitiveValue:_availableMediaCount forKey:@"availableDiscCount"];
    if (movie && (oldValue != newValue)) {
        if (newValue > oldValue) {
            movie.availableDiscCount = [NSNumber numberWithInt:[movie.availableDiscCount intValue] + 1];
        } else {
            movie.availableDiscCount = [NSNumber numberWithInt:[movie.availableDiscCount intValue] - 1];
        }
    }
    [super didChangeValueForKey:@"availableDiscCount"];
}

@end
