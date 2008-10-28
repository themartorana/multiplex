#import <Cocoa/Cocoa.h>

@class Disc;
@class Engine;

@interface Media : NSManagedObject {
}

@property (retain) NSString* tag;
@property (retain) NSString* type;
@property (retain) Disc* disc;
@property (retain) Engine* engine;
@property (retain) NSNumber* isAvailable;

@end
