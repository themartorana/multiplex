#import <Foundation/Foundation.h>

@protocol MediaSource;
@class Disc;

@interface Media : NSObject {
	MDItemRef itemRef;
	NSDictionary* info;
	Disc* disc;
    BOOL isPhysicalMedia;
    id<MediaSource> mediaSource;
}

- (id) initWithMediaSource:(id<MediaSource>)mediaSource MDItemRef:(MDItemRef)itemRef;
- (id) initWithMediaSource:(id<MediaSource>)mediaSource physicalMedia:(NSString*)fingerprint atPath:(NSString*)pathToMedia;

@property (retain) Disc* disc;
@property (readonly) NSString* contentType;
@property (readonly) NSString* fingerprint;
@property (readonly) NSString* pathToFile;
@property (readonly) BOOL isPhysicalMedia;
@property (readonly) id<MediaSource> mediaSource;

- (void) reload;

extern const CFStringRef kMDDiscDiscIdentFingerprint;

@end
