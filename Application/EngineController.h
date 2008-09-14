#import <Cocoa/Cocoa.h>

@interface EngineController : NSObject {
    NSMutableDictionary* netServiceByName;
    NSMutableDictionary* protocolsByUUID;
    /**/
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
- (void) stop;

@end
