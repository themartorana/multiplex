//
//  MainController.m
//  Library
//
//  Created by David Martorana on 8/8/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MainController.h"
#import "EngineController.h" 

@implementation MainController

- (id) init {
    if (self == [super init]) {
        _nsmom = [NSManagedObjectModel mergedModelFromBundles:nil];
        _nspsc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:_nsmom];
        _nsmoc = [[NSManagedObjectContext alloc] init];
        [_nsmoc setPersistentStoreCoordinator:_nspsc];

        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(coreDataChangeNotification:) 
                                                     name:NSManagedObjectContextObjectsDidChangeNotification 
                                                   object:_nsmoc];
        
        _enginesManager = [[[EnginesManager alloc] initWithManagedObjectContext:_nsmoc] retain];
    }
    
    return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self.window makeKeyAndOrderFront:nil];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
    [_enginesManager closeAllEngines];
}


// Return the managed object context
- (NSManagedObjectContext *) managedObjectContext {
    return _nsmoc;
}


///
/// Launch the selected movie
/// 
- (IBAction) launchMovie:(id)sender {
    NSManagedObject* discMO = [[_discsController selectedObjects] objectAtIndex:0];
    NSURL* url = [NSURL URLWithString:[discMO valueForKey:@"url"]];
    [[NSWorkspace sharedWorkspace] openURL:url];
    
    return;
}


///
/// When an object in Core Data changes, send it along its way
///
- (void) coreDataChangeNotification:(NSNotification*)notification
{
    // We're only interested in the changes for now
    NSSet* set = [[notification userInfo] objectForKey:NSUpdatedObjectsKey];
    
    if (set) {
        for (NSManagedObject* mo in set) {
            NSString* entityName = [[mo entity] name];
            
            NSManagedObject* discMO;
            NSManagedObject* movieMO;
            NSManagedObject* engineMO;
            
            if ([@"Disc" isEqualToString:entityName]) {
                discMO = mo;
                movieMO = [discMO valueForKey:@"discMovie"];
            }
            else if ([@"Movie" isEqualToString:entityName]) {
                movieMO = mo;
            }
            else
                return;
            
            // Get the engine MO
            engineMO = [movieMO valueForKey:@"movieEngine"];
            
            // Set up our message dictionary
            NSMutableDictionary* messageDict = [NSMutableDictionary dictionary];
            
            // Get the engine to send the updates to
            NSString* engineUUID = [engineMO valueForKey:@"UUID"];
            EngineController* ec = [_enginesManager engineByUUIDKey:engineUUID];
            
            // If this is a disc, we have to just send one update.  If this is 
            // a movie, we have to apply it to all the discs in that movie
            if ([entityName isEqualToString:@"Disc"]) {
                [messageDict setValue:[discMO valueForKey:@"com_discident_fingerprint"] forKey:@"com_discident_fingerprint"];
                [messageDict setValue:[discMO valueForKey:@"url"] forKey:@"url"];
                
                // Now set any changes to the disc
                for (NSString* changeKey in [discMO changedValues]) {
                    if (![changeKey isEqualToString:@"discMovie"]) {
                        [messageDict setValue:[discMO valueForKey:changeKey] forKey:changeKey];
                    }
                }
                
                // Send the message
                [ec sendAMessage:[NSDictionary dictionaryWithDictionary:messageDict]];
            }
            else if ([entityName isEqualToString:@"Movie"]) {
                for (NSManagedObject* disc in [movieMO valueForKey:@"movieDiscs"]) {
                    
                    // Start fresh with the dictionary
                    [messageDict removeAllObjects];
                    
                    // The disc
                    discMO = disc;
                    [messageDict setValue:[discMO valueForKey:@"com_discident_fingerprint"] forKey:@"com_discident_fingerprint"];
                    [messageDict setValue:[discMO valueForKey:@"url"] forKey:@"url"];
                    
                    // Now apply the movie changes
                    for (NSString* changeKey in [movieMO changedValues]) {
                        if (![changeKey isEqualToString:@"movieEngine"] && ![changeKey isEqualToString:@"movieDiscs"]) {
                            [messageDict setValue:[movieMO valueForKey:changeKey] forKey:changeKey];   
                        }
                    }
                    
                    // Sent the message
                    [ec sendAMessage:[NSDictionary dictionaryWithDictionary:messageDict]];
                }
            }
        }
    }
}


- (void) dealloc {
    [_enginesManager release];
    [super dealloc];
}

@end
