#import <Cocoa/Cocoa.h>
#import "Media.h"

@interface Disc : NSObject {
	NSString* fingerprint;
    NSMutableArray* allMedia;
    NSMutableDictionary* infoDictionary;
}

- (id) initWithFingerprint:(NSString*)fingerprint media:(Media*)media;

@property (readonly) NSString* contentType;
@property (readonly) NSString* fingerprint;
@property (readonly) BOOL hasDisc;
@property (readonly) NSString* pathToFile;
@property (readonly) BOOL isPhysicalMedia;
@property (retain) NSMutableDictionary* infoDictionary;

- (void) addMedia:(Media*)media;
- (void) removeMedia:(Media*)media;

@end
