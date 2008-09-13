#import <Foundation/Foundation.h>

@protocol MediaSource;
@class Disc;

@interface Media : NSObject {
    void* mediaInfo;
    NSString* fingerprint;
    Disc* disc;
    NSURL* url;
    id<MediaSource> mediaSource;
}

- (id) initWithMediaSource:(id<MediaSource>)mediaSource mediaInfo:(void*)mediaInfo;

@property (readonly) void* mediaInfo;

@property (retain) Disc* disc;
@property (retain) NSURL* url;
@property (retain) NSString* fingerprint;
@property (readonly) NSString* pathToFile;
@property (readonly) id<MediaSource> mediaSource;
@property (assign) NSMutableDictionary* infoDictionary;

- (void) reload;
- (void) setFrontCover:(NSImage*)coverArt;

@end

extern const CFStringRef kMDDiscDiscIdentFingerprint;