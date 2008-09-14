#import <Cocoa/Cocoa.h>

@class Engine;

@interface EngineController : NSObject {
    NSMutableDictionary* netServiceByName;
    NSMutableDictionary* protocolsByUUID;
    /**/
    NSDateFormatter* dateFormatter;
    NSManagedObjectContext* managedObjectContext;
    NSNetServiceBrowser* browser;
    NSString* localMachineUUID;
    BOOL pushingBackChanges;
    /**/
    NSEntityDescription* engineDesc;
    NSEntityDescription* mediaDesc;
    NSEntityDescription* discDesc;
    NSEntityDescription* movieDesc;
}

- (id) initWithManagedObjectContext:(NSManagedObjectContext*)managedObjectContext;

- (void) shutdown;
- (BOOL) connectEngine:(Engine*)engine;
- (void) disconnectEngine:(Engine*)engine;

@end
