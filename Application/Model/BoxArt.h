#import <Cocoa/Cocoa.h>

@interface BoxArt : NSManagedObject {
}

@property (retain) NSString* url;
@property (retain) NSData* image;
@property (retain) NSString* type;
@property (retain) NSString* state;

@end
