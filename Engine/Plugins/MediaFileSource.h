#import <Foundation/Foundation.h>
#import "MediaFile.h"

@protocol MediaFileSourceDelegate;

@protocol MediaFileSource

@property (assign) id<MediaFileSourceDelegate> delegate;
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

@protocol MediaFileSourceDelegate

- (void) mediaFileSource:(id<MediaFileSource>)mediaSource didAddMedia:(NSArray*)media;
- (void) mediaFileSource:(id<MediaFileSource>)mediaSource didUpdateMedia:(NSArray*)media;
- (void) mediaFileSource:(id<MediaFileSource>)mediaSource didRemoveMedia:(NSArray*)media;

@end

