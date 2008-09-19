#import "Media.h"

@protocol MediaSourceDelegate;

@protocol MediaSource

@property (assign) id<MediaSourceDelegate> delegate;
- (void) start;
- (void) stop;
- (NSMutableDictionary*) infoDictionaryForMedia:(Media*)media;
- (void) setInfoDictionary:(NSMutableDictionary*)infoDictionary forMedia:(Media*)media;
- (NSData*) frontCoverForMedia:(Media*)media;
- (void) setFrontCover:(NSData*)frontCover forMedia:(Media*)media;
- (NSString*) pathToFileForMedia:(Media*)media;
- (NSString*) fingerprintForMedia:(Media*)media;
- (void) reloadMedia:(Media*)media;
@end

@protocol MediaSourceDelegate

- (void) mediaSource:(id<MediaSource>)mediaSource didAddMedia:(NSArray*)media;
- (void) mediaSource:(id<MediaSource>)mediaSource didUpdateMedia:(NSArray*)media;
- (void) mediaSource:(id<MediaSource>)mediaSource didRemoveMedia:(NSArray*)media;

@end
