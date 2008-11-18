#import <Cocoa/Cocoa.h>

@class Disc;

@interface Episode : NSObject {
}

@property (retain) NSString* title;
@property (retain) NSDate* airDate;
@property (retain) NSString* network;
@property (retain) NSNumber* runningTime;
@property (retain) NSString* synopsis;

@property (retain) Disc* disc;
@property (readonly) NSMutableSet* allParticipants;

@end
