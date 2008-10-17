#import <Cocoa/Cocoa.h>

extern NSString* const kLoadingCoverArtActivityName;

@class Engine;

@interface EngineController : NSObject {
    NSMutableDictionary* netServiceByName;
    NSMutableDictionary* protocolsByUUID;
    
    NSMutableDictionary* discsByFingerprint;
    /**/
    NSDateFormatter* dateFormatter;
    NSManagedObjectContext* managedObjectContext;
    NSNetServiceBrowser* browser;
    NSString* localMachineUUID;
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
