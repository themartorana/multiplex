#import <Foundation/Foundation.h>

@protocol MediaSource;
@class Disc;

@interface Media : NSObject {
	MDItemRef itemRef;
	NSDictionary* info;
	Disc* disc;
    BOOL isPhysicalMedia;
    id<MediaSource> mediaSource;
    NSURL* url;
}

- (id) initWithMediaSource:(id<MediaSource>)mediaSource MDItemRef:(MDItemRef)itemRef;
- (id) initWithMediaSource:(id<MediaSource>)mediaSource physicalMedia:(NSString*)fingerprint atPath:(NSString*)pathToMedia;

@property (retain) Disc* disc;
@property (retain) NSURL* url;
@property (readonly) NSString* contentType;
@property (readonly) NSString* fingerprint;
@property (readonly) NSString* pathToFile;
@property (readonly) BOOL isPhysicalMedia;
@property (readonly) id<MediaSource> mediaSource;
@property (assign) NSMutableDictionary* infoDictionary;

- (void) reload;

- (void) setFrontCover:(NSImage*)coverArt;

@end

extern const CFStringRef kMDDiscDiscIdentFingerprint;