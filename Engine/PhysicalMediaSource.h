#import <Cocoa/Cocoa.h>
#import "MediaSource.h"

@interface PhysicalMediaSource : NSObject <MediaSource> {
    BOOL started;
    NSMutableDictionary* discsByDeviceName;
    id<MediaSourceDelegate> delegate;
}

@property (assign) id<MediaSourceDelegate> delegate;
- (void) start;
- (void) stop;

@end
