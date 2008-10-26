#import <Cocoa/Cocoa.h>
#import "MediaFileSource.h"

@interface DVDMediaSource : NSObject <MediaFileSource> {
    MDQueryRef query;
    int mediaProcessed;
    id<MediaFileSourceDelegate> delegate;
}

@property (assign) id<MediaFileSourceDelegate> delegate;

- (void) start;
- (void) stop;

@end
