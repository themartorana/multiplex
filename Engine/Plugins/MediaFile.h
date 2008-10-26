#import <Foundation/Foundation.h>

@protocol MediaFileSource;
@class Disc;

@interface MediaFile : NSObject {
    void* mediaInfo;
    NSString* fingerprint;
    Disc* disc;
    NSURL* url;
    id<MediaFileSource> mediaFileSource;
}

- (id) initWithMediaSource:(id<MediaFileSource>)mediaSource mediaInfo:(void*)mediaInfo;

@property (readonly) void* mediaInfo;

@property (retain) Disc* disc;
@property (retain) NSURL* url;
@property (retain) NSString* fingerprint;
@property (readonly) NSString* pathToFile;
@property (readonly) id<MediaFileSource> mediaFileSource;
@property (assign) NSMutableDictionary* infoDictionary;
@property (assign) NSData* frontCover;

- (void) reload;

@end

extern const CFStringRef kMDDiscDiscIdentFingerprint;