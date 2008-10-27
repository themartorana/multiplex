#import <Cocoa/Cocoa.h>

@class Disc;
@class Engine;

@interface Media : NSManagedObject {
    Disc* disc;
    NSNumber* isAvailable;
}

@property (retain) NSString* url;
@property (retain) Disc* disc;
@property (retain) Engine* engine;
@property (retain) NSNumber* isAvailable;

@end
