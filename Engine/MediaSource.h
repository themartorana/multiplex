#import "MediaFile.h"

@protocol MediaSourceDelegate;

@protocol MediaSource

@property (assign) id<MediaSourceDelegate> delegate;
- (void) start;
- (void) stop;
- (NSMutableDictionary*) infoDictionaryForMedia:(MediaFile*)media;
- (void) setInfoDictionary:(NSMutableDictionary*)infoDictionary forMedia:(MediaFile*)media;
- (NSData*) frontCoverForMedia:(MediaFile*)media;
- (void) setFrontCover:(NSData*)frontCover forMedia:(MediaFile*)media;
- (NSString*) pathToFileForMedia:(MediaFile*)media;
- (NSString*) fingerprintForMedia:(MediaFile*)media;
- (void) reloadMedia:(MediaFile*)media;
@end

@protocol MediaSourceDelegate

- (void) mediaSource:(id<MediaSource>)mediaSource didAddMedia:(NSArray*)media;
- (void) mediaSource:(id<MediaSource>)mediaSource didUpdateMedia:(NSArray*)media;
- (void) mediaSource:(id<MediaSource>)mediaSource didRemoveMedia:(NSArray*)media;

@end
