#import <Cocoa/Cocoa.h>

@interface BoxArt : NSManagedObject {
}

@property (retain) NSString* url;
@property (assign) CGImageRef image;
@property (retain) NSString* type;
@property (retain) NSString* state;
@property (retain) NSData *imageData;

@property (retain) NSSet *allDiscs;

@end
