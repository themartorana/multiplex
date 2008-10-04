//
//  Activity.m
//  Multiplex
//
//  Created by David Martorana on 10/1/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "Activity.h"


@implementation Activity

@synthesize activityName;
@synthesize activityUUID;
@synthesize delegate;
@synthesize percentComplete;
@synthesize showActivity;
@synthesize terminated;

- (Activity*) initWithActivityName:(NSString*)_activityName andShowInUI:(BOOL)_show
{
    if (self = [super init]) {
        self.activityName = _activityName;
        self.percentComplete = 0.0;       
        self.showActivity = _show;
        self.terminated = NO;
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ActivityStarted" object:self];
    }
    
    return self;
}

- (void) dealloc
{
    [super dealloc];
}

- (void) setPercentComplete:(float)percent
{
    percentComplete = percent;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ActivityPercentCompleteUpdated" object:self];
}

- (void) terminate
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ActivityTerminated" object:self];
    self.terminated = YES;
}

@end
