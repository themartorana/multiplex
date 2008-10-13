#import <Cocoa/Cocoa.h>

@class Disc;
@class Engine;

@interface Media : NSManagedObject {
}

@property (retain) NSString* url;
@property (retain) Disc* disc;
@property (retain) Engine* engine;
@property (retain) NSNumber* isAvailable;

@end
