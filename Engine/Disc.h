#import <Foundation/Foundation.h>

@protocol MediaSource;
@class Movie;

@interface Disc : NSObject {
	MDItemRef itemRef;
	NSDictionary* info;
	Movie* movie;
    BOOL isPhysicalMedia;
    id<MediaSource> mediaSource;
}

- (id) initWithMediaSource:(id<MediaSource>)mediaSource MDItemRef:(MDItemRef)itemRef;
- (id) initWithMediaSource:(id<MediaSource>)mediaSource physicalMedia:(NSString*)fingerprint atPath:(NSString*)pathToMedia;

@property (retain) Movie* movie;
@property (readonly) NSString* contentType;
@property (readonly) NSString* fingerprint;
@property (readonly) NSString* pathToFile;
@property (readonly) BOOL isPhysicalMedia;
@property (readonly) id<MediaSource> mediaSource;

- (void) reload;

@end
