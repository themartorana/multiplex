#import <Cocoa/Cocoa.h>
#import "Movie.h"

@interface Participant : NSManagedObject {
}

@property (retain) NSString* name;
@property (retain) NSString* position;
@property (retain) NSString* type;

@property (retain) Movie* movie;

@end
