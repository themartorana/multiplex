#import <Cocoa/Cocoa.h>
#import "MediaFile.h"

@interface Disc : NSObject {
    NSString* fingerprint;
    NSMutableArray* allMedia;
    NSMutableDictionary* infoDictionary;
}

- (id) initWithFingerprint:(NSString*)fingerprint media:(MediaFile*)media;

@property (readonly) NSString* contentType;
@property (readonly) NSString* fingerprint;
@property (readonly) BOOL hasDisc;
@property (readonly) NSString* pathToFile;
@property (readonly) BOOL isPhysicalMedia;
@property (readonly) NSMutableArray* allMedia;
@property (retain) NSMutableDictionary* infoDictionary;

- (void) addMedia:(MediaFile*)media;
- (void) removeMedia:(MediaFile*)media;

@end
