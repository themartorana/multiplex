#import <Cocoa/Cocoa.h>

@interface MediaLocator : NSManagedObject {
}

@property (retain) NSString* pathToFile;
@property (retain) NSString* tag;
@property (retain) NSString* fingerprint;
@property (retain) NSString* type;
@property (retain) NSDate* lastSeen;
@property (retain) NSNumber* isAvailable;
@property (retain) NSNumber* hasFrontCover;
@property (retain) NSNumber* hasInfo;

@end
