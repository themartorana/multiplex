#import <Cocoa/Cocoa.h>

@class MessageProtocol;

@interface EngineController : NSObject {
    NSTask* engineTask;
    MessageProtocol* protocol;
    NSManagedObjectContext* managedObjectContext;
    NSManagedObject* engineManagedObject;
    
    NSString* engineName;
    NSString* engineAddress;
    NSString* UUID;
}

@property (readwrite, retain) NSString* engineName;
@property (readonly) NSString* UUID;
@property (readonly) NSString* engineAddress;

- (id) initWithLocalEngine:(NSManagedObjectContext*)managedObjectContext;

- (void) sendMessage:(NSDictionary*)message;
- (BOOL) close;

@end
