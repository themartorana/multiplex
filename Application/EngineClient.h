#import <Cocoa/Cocoa.h>

@class MessageProtocol;

@interface EngineClient : NSObject {
    NSString* machineName;
    NSString* machineId;
    NSNetService* netService;

    NSManagedObjectContext* managedObjectContext;

    MessageProtocol* protocol;
    NSEntityDescription* mediaDesc;
    NSEntityDescription* discDesc;
    NSEntityDescription* movieDesc;
}

@property (readwrite, retain) NSString* machineName;
@property (readonly) NSString* machineId;

- (id) initWithNetService:(NSNetService*)_netService managedObjectContext:(NSManagedObjectContext*)_managedObjectContext options:(NSDictionary*)_options;

- (void) sendMessage:(NSDictionary*)message;

- (BOOL) connect;
- (void) disconnect;

@end
