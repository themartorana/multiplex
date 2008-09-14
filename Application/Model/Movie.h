#import <Cocoa/Cocoa.h>

@interface Movie : NSManagedObject {
}

@property (retain) NSString* gtin;
@property (retain) NSString* aspectRatio;
@property (retain) NSString* review;
@property (retain) NSString* synopsis;
@property (retain) NSString* title;

@property (readonly) NSSet* allDiscs;

@end
