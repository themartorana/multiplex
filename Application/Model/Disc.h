#import <Cocoa/Cocoa.h>

@class Movie;

@interface Disc : NSManagedObject {
}

@property (retain) Movie* movie;
@property (retain) NSString* fingerprint;
@property (retain) NSNumber* number;
@property (retain) NSString* side;
@property (retain) NSString* description;

@property (readonly) NSSet* allMedia;

@end