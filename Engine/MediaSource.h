

@protocol MediaSourceDelegate;

@protocol MediaSource

@property (assign) id<MediaSourceDelegate> delegate;
- (void) start;
- (void) stop;

@end

@protocol MediaSourceDelegate

- (void) mediaSource:(id<MediaSource>)mediaSource didAddDiscs:(NSArray*)discs;
- (void) mediaSource:(id<MediaSource>)mediaSource didUpdateDiscs:(NSArray*)discs;
- (void) mediaSource:(id<MediaSource>)mediaSource didRemoveDiscs:(NSArray*)discs;

@end
