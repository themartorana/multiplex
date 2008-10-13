#import <Cocoa/Cocoa.h>

extern NSString* const ActivityStartedNotification;
extern NSString* const ActivityTerminatedNotification;
extern NSString* const ActivityPercentCompleteUpdatedNotification;

@interface Activity : NSObject {
    NSString* UUID;
    NSString* name;
    
    BOOL isComplete;
    float percentComplete;
    id delegate;
    id userInfo;
}

@property (retain) NSString* name;
@property (retain) NSString* UUID;
@property (retain) id delegate;
@property (readonly) float percentComplete;
@property (retain) id userInfo;
@property (readonly) BOOL isComplete;

+ (id) activityWithName:(NSString*)activityName userInfo:(id)userInfo;

- (id) initWithName:(NSString*)activityName userInfo:(id)userInfo;

- (void) terminate;

@end
