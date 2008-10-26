#import <Cocoa/Cocoa.h>
#import "MediaFileSource.h"

@interface PhysicalMediaSource : NSObject <MediaFileSource> {
    BOOL started;
    NSMutableDictionary* mediaByDeviceName;
    id<MediaFileSourceDelegate> delegate;
}

@property (assign) id<MediaFileSourceDelegate> delegate;
- (void) start;
- (void) stop;

@end
