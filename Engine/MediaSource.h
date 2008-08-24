

@protocol MediaSourceDelegate;

@protocol MediaSource

@property (assign) id<MediaSourceDelegate> delegate;
- (void) start;
- (void) stop;

@end

@protocol MediaSourceDelegate

- (void) mediaSource:(id<MediaSource>)mediaSource didAddItems:(NSArray*)items;
- (void) mediaSource:(id<MediaSource>)mediaSource didUpdateItems:(NSArray*)items;
- (void) mediaSource:(id<MediaSource>)mediaSource didRemoveItems:(NSArray*)items;

@end
