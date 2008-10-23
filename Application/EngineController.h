#import <Cocoa/Cocoa.h>

extern NSString* const kLoadingBoxArtActivityName;

@class Engine;

@interface EngineController : NSObject {
    NSMutableDictionary* netServiceByName;
    NSMutableDictionary* protocolsByUUID;
    /**/
    NSDateFormatter* dateFormatter;
    NSManagedObjectContext* managedObjectContext;
    NSNetServiceBrowser* browser;
    NSString* localMachineUUID;
    /**/
    NSEntityDescription* engineEntity;
    NSEntityDescription* mediaEntity;
    NSEntityDescription* discEntity;
    NSEntityDescription* movieEntity;
    NSEntityDescription* boxArtEntity;
}

- (id) initWithManagedObjectContext:(NSManagedObjectContext*)managedObjectContext;

- (void) shutdown;
- (BOOL) connectEngine:(Engine*)engine;
- (void) disconnectEngine:(Engine*)engine;

@end
