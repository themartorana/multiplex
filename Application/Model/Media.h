#import <Cocoa/Cocoa.h>

@class Disc;
@class Engine;

@interface Media : NSManagedObject {
    Disc* disc;
    NSNumber* isAvailable;
}

@property (retain) NSString* tag;
@property (retain) NSString* type;
@property (retain) NSString* pathToFile;
@property (retain) Disc* disc;
@property (retain) Engine* engine;
@property (retain) NSNumber* isAvailable;
@property (retain) NSNumber* isLocal;

- (void) setDisc:(Disc*)_disc;
- (void) setIsAvailable:(NSNumber*)_isAvailable;

@end
