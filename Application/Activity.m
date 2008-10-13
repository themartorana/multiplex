#import "Activity.h"
#import "NSString+UUID.h"

NSString* const ActivityStartedNotification = @"ActivityStarted";
NSString* const ActivityTerminatedNotification = @"ActivityTerminated";
NSString* const ActivityPercentCompleteUpdatedNotification = @"ActivityPercentCompleteUpdated";

@implementation Activity

@synthesize name;
@synthesize UUID;
@synthesize delegate;
@synthesize percentComplete;
@synthesize isComplete;
@synthesize userInfo;

+ (id) activityWithName:(NSString*)_activityName userInfo:(id)_userInfo
{
    return [[[Activity alloc] initWithName:_activityName userInfo:_userInfo] autorelease];
}

- (id) initWithName:(NSString*)_activityName userInfo:(id)_userInfo
{
    if (self = [super init]) {
        name = [_activityName retain];
        userInfo = [_userInfo retain];
        UUID = [[NSString stringWithUUID] retain];
        percentComplete = 0.0;       
        isComplete = NO;
        
        [[NSNotificationCenter defaultCenter] postNotificationName:ActivityStartedNotification object:self];
    }
    
    return self;
}

- (void) dealloc
{
    [name release];
    [UUID release];
    [userInfo release];
    [super dealloc];
}

- (void) setPercentComplete:(float)percent
{
    percentComplete = percent;
    [[NSNotificationCenter defaultCenter] postNotificationName:ActivityPercentCompleteUpdatedNotification object:self];
}

- (void) terminate
{
    if (!isComplete) {
        [[NSNotificationCenter defaultCenter] postNotificationName:ActivityTerminatedNotification object:self];
        isComplete = YES;
    }
}

@end
