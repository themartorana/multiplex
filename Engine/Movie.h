#import <Cocoa/Cocoa.h>

@class Disc;

@interface Movie : NSObject {
	NSString* fingerprint;
    NSMutableArray* discs;
}

- (id) initWithDisc:(Disc*)disc;

- (NSString*) contentType;
- (NSString*) fingerprint;
- (BOOL) hasDisc;
- (NSString*) pathToFile;
- (BOOL) isPhysicalMedia;

- (void) addDisc:(Disc*)disc;
- (void) removeDisc:(Disc*)disc;

@end
