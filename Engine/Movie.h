#import <Cocoa/Cocoa.h>

@class Disc;

@interface Movie : NSObject {
	NSString* fingerprint;
    NSMutableArray* items;
}

- (id) initWithItem:(Disc*)item;

- (NSString*) contentType;
- (NSString*) fingerprint;
- (BOOL) hasItem;
- (NSString*) pathToFile;
- (BOOL) isPhysicalMedia;

- (void) addItem:(Disc*)item;
- (void) removeItem:(Disc*)item;

@end
