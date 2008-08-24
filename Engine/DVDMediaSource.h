#import <Cocoa/Cocoa.h>
#import "MediaSource.h"

@interface DVDMediaSource : NSObject <MediaSource> {
	MDQueryRef query;
    int itemsProcessed;
    id<MediaSourceDelegate> delegate;
}

@property (assign) id<MediaSourceDelegate> delegate;
- (void) start;
- (void) stop;

@end
