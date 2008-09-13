#import <Cocoa/Cocoa.h>
#import "EngineClient.h"

@interface EngineClientController : NSObject {
    NSMutableDictionary* engineControllers;
    NSManagedObjectContext* managedObjectContext;
    NSNetServiceBrowser* browser;
    NSUserDefaults* engineDefaults;
    NSString* localEngineID;
    NSTask* localEngine;
    NSMutableArray* netServices;
}

- (id) initWithManagedObjectContext:(NSManagedObjectContext*)managedObjectContext;
- (void) stop;
- (EngineClient*) engineByUUIDKey:(NSString*)UUIDKey;

@property (readonly) NSString* localEngineID;

@end
