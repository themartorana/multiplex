#import <CoreData/CoreData.h>

@interface Disc : NSManagedObject {
}

@property (retain) NSString* fingerprint;
@property (retain) NSDictionary* infoDictionary;
@property (retain) NSMutableSet* allMediaLocators;

@end
