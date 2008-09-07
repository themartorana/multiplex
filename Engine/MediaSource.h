#import "Media.h"

@protocol MediaSourceDelegate;

@protocol MediaSource

@property (assign) id<MediaSourceDelegate> delegate;
- (void) start;
- (void) stop;
- (NSMutableDictionary*) infoDictionaryForMedia:(Media*)media;
- (void) setInfoDictionary:(NSMutableDictionary*)infoDictionary forMedia:(Media*)media;
@end

@protocol MediaSourceDelegate

- (void) mediaSource:(id<MediaSource>)mediaSource didAddMedia:(NSArray*)media;
- (void) mediaSource:(id<MediaSource>)mediaSource didUpdateMedia:(NSArray*)media;
- (void) mediaSource:(id<MediaSource>)mediaSource didRemoveMedia:(NSArray*)media;

@end
