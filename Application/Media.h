#import <Cocoa/Cocoa.h>

@class Disc;

@interface Media : NSManagedObject {
}

@property (retain) NSString* url;
@property (retain) Disc* disc;
@property (retain) NSString* machineId;

@end
