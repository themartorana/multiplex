#import <Cocoa/Cocoa.h>
#import "EngineController.h"

@interface EnginesManager : NSObject {
    NSMutableDictionary* engineControllers;
    NSManagedObjectContext* managedObjectContext;
    NSNetServiceBrowser* browser;
    NSUserDefaults* engineDefaults;
    NSString* localEngineID;
    NSTask* localEngine;
    NSMutableArray* netServices;
}

- (id) initWithManagedObjectContext:(NSManagedObjectContext*)_managedObjectContext;
- (void) stop;
- (EngineController*) engineByUUIDKey:(NSString*)UUIDKey;

@property (readonly) NSString* localEngineID;

@end
