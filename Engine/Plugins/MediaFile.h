#import <Foundation/Foundation.h>

@protocol MediaFileSource;
@class Disc;

@interface MediaFile : NSObject {
    void* mediaInfo;
    NSString* tag;
    id<MediaFileSource> mediaFileSource;
}

- (id) initWithMediaSource:(id<MediaFileSource>)mediaSource mediaInfo:(void*)mediaInfo;

@property (readonly) void* mediaInfo;

@property (retain) NSString* tag;
@property (readonly) NSString* fingerprint;
@property (readonly) NSString* type;
@property (readonly) NSString* pathToFile;
@property (readonly) id<MediaFileSource> mediaFileSource;
@property (assign) NSMutableDictionary* infoDictionary;
@property (assign) NSData* frontCover;

- (void) reload;

@end

extern const CFStringRef kMDDiscDiscIdentFingerprint;