#import <Cocoa/Cocoa.h>

@class Disc;

@interface MediaLocator : NSManagedObject {
}

@property (retain) NSString* fileSystemID;
@property (retain) NSString* relativePath;
@property (retain) NSNumber* isAvailable;
@property (retain) NSDate* lastSeen;
@property (retain) NSString* tag;
@property (retain) Disc* disc;

@end
