#import <Cocoa/Cocoa.h>

@class Movie;
@class BoxArt;

@interface Disc : NSManagedObject {
}

@property (retain) BoxArt* boxArt;
@property (retain) Movie* movie;
@property (retain) NSString* fingerprint;
@property (retain) NSNumber* number;
@property (retain) NSString* side;
@property (retain) NSString* synopsis;
@property (retain) NSNumber* availableMediaCount;
@property (retain) NSNumber* localMediaCount;
@property (retain) NSString* discTitle;

@property (readonly) NSMutableSet* allMedia;

@end