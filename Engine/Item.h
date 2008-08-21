#import <Foundation/Foundation.h>

@class Movie;

@interface Item : NSObject {
	MDItemRef itemRef;
	NSDictionary* info;
	Movie* movie;
}

- (id) initWithMDItemRef:(MDItemRef)itemRef;

@property (retain) Movie* movie;
@property (readonly) NSString* contentType;
@property (readonly) NSString* fingerprint;
@property (readonly) NSString* pathToFile;

- (void) reload;

@end
