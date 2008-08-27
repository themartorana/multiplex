//
//  EngineController.h
//  Library
//
//  Created by David Martorana on 8/8/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MessageProtocol.h"


@interface EngineController : NSObject {
    NSTask* _engineTask;
    MessageProtocol* _protocol;
    NSManagedObjectContext* _nsmoc;
    NSManagedObject* _engineManagedObject;
    
    NSString* engineName;
    NSString* engineAddress;
    NSString* UUID;
}

@property (readwrite, retain) NSString* engineName;
@property (readonly) NSString* UUID;
@property (readonly) NSString* engineAddress;

- (id) initWithLocalEngine:(NSManagedObjectContext*)managedObjectContext;
- (void) sendAMessage:(NSDictionary*)dict;
- (BOOL) close;
- (void) generateUUID;
- (void) addEntityDescription;

@end
