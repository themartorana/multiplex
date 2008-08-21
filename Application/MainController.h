//
//  MainController.h
//  Library
//
//  Created by David Martorana on 8/8/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "EnginesManager.h"


@interface MainController : NSWindowController {
    EnginesManager* _enginesManager;
    NSManagedObjectModel* _nsmom;
    NSPersistentStoreCoordinator* _nspsc;
    NSManagedObjectContext* _nsmoc;
    
    IBOutlet NSArrayController *_discsController;
}

- (IBAction) launchMovie:(id)sender;

@end
