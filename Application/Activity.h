//
//  Activity.h
//  Multiplex
//
//  Created by David Martorana on 10/1/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface Activity : NSObject {
    NSString* activityUUID;
    NSString* activityName;
    
    BOOL showActivity;
    BOOL terminated;
    
    float percentComplete;

    id delegate;
}

@property (retain) NSString* activityName;
@property (retain) NSString* activityUUID;
@property (retain) id delegate;
@property float percentComplete;
@property BOOL showActivity;
@property BOOL terminated;

- (Activity*) initWithActivityName:(NSString*)_activityName andShowInUI:(BOOL)_show;
- (void) terminate;

@end
