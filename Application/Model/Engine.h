#import <Cocoa/Cocoa.h>

@interface Engine : NSManagedObject {
}

@property (retain) NSString* uuid;
@property (retain) NSString* name;
@property (retain) NSString* netServiceName;
@property (retain) NSString* status;

@property (retain) NSMutableSet* allMedia;

@end
