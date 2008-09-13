#import <Cocoa/Cocoa.h>
#import "EngineConnection.h"

@interface EngineController : NSObject {
    NSMutableDictionary* engineControllers;
    NSManagedObjectContext* managedObjectContext;
    NSNetServiceBrowser* browser;
    NSUserDefaults* engineDefaults;
    NSString* localMachineID;
    NSTask* localEngine;
    NSMutableArray* netServices;
}

- (id) initWithManagedObjectContext:(NSManagedObjectContext*)managedObjectContext;
- (void) stop;

@end
