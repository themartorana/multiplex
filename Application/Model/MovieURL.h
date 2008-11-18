#import <Cocoa/Cocoa.h>
#import "Movie.h"

@interface MovieURL : NSManagedObject {
}

@property (retain) NSString* url;
@property (retain) NSString* siteName;
@property (retain) Movie* movie;

@end
