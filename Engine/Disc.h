#import <Cocoa/Cocoa.h>
#import "Media.h"

@interface Disc : NSObject {
	NSString* fingerprint;
    NSMutableArray* allMedia;
}

- (id) initWithMedia:(Media*)media;

- (NSString*) contentType;
- (NSString*) fingerprint;
- (BOOL) hasDisc;
- (NSString*) pathToFile;
- (BOOL) isPhysicalMedia;

- (void) addMedia:(Media*)media;
- (void) removeMedia:(Media*)media;

@end
