//
//  EnginesManager.h
//  Library
//
//  Created by David Martorana on 8/9/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "EngineController.h"

@interface EnginesManager : NSObject {
    NSMutableDictionary* _engines;
    NSManagedObjectContext* _nsmoc;
}

- (id) initWithManagedObjectContext:(NSManagedObjectContext*)managedObjectContext;
- (void) closeAllEngines;
- (EngineController*) engineByUUIDKey:(NSString*)UUIDKey;

@end
