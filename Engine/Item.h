#import <Foundation/Foundation.h>

@class Movie;

@interface Item : NSObject {
	MDItemRef itemRef;
	NSDictionary* info;
	Movie* movie;
    BOOL isPhysicalMedia;
}

- (id) initWithMDItemRef:(MDItemRef)itemRef;
- (id) initWithPhysicalMedia:(NSString*)fingerprint atPath:(NSString*)pathToMedia;

@property (retain) Movie* movie;
@property (readonly) NSString* contentType;
@property (readonly) NSString* fingerprint;
@property (readonly) NSString* pathToFile;
@property (readonly) BOOL isPhysicalMedia;

- (void) reload;

@end
