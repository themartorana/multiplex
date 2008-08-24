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
@synthesize managedObjectContext;

- (id) init 
{
    if (self == [super init]) {
        managedObjectModel = [[NSManagedObjectModel mergedModelFromBundles:nil] retain];

        persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:managedObjectModel];
        [persistentStoreCoordinator addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:nil options:nil error:nil];

        managedObjectContext = [[NSManagedObjectContext alloc] init];
        [managedObjectContext setPersistentStoreCoordinator:persistentStoreCoordinator];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_coreDataChangeNotification:) name:NSManagedObjectContextObjectsDidChangeNotification object:managedObjectContext];
        
        enginesManager = [[EnginesManager alloc] initWithManagedObjectContext:managedObjectContext];
    }
    return self;
}

- (void) dealloc 
{
    [managedObjectModel release];
    [persistentStoreCoordinator release];
    [managedObjectContext release];
    [enginesManager release];
    [super dealloc];
}

- (void) applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self.window makeKeyAndOrderFront:nil];
}

- (void) applicationWillTerminate:(NSNotification *)aNotification
{
    [enginesManager closeAllEngines];
}


///
/// Launch the selected movie
/// 
- (IBAction) launchMovie:(id)sender 
{
    NSManagedObject* disc = [[discsController selectedObjects] objectAtIndex:0];
    if (disc) {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[disc valueForKey:@"url"]]];
    }
}

@end

@implementation MainController (Private)

///
/// When an object in Core Data changes, send it along its way
///
- (void) _coreDataChangeNotification:(NSNotification*)notification
{
    NSMutableDictionary* setsOfFingerprintsForEngineControllerByUUID = [NSMutableDictionary dictionary];
    NSMutableDictionary* updatesByFingerprint = [NSMutableDictionary dictionary];
    for (NSManagedObject* managedObject in [[notification userInfo] objectForKey:NSUpdatedObjectsKey]) {
        NSString* entityName = [[managedObject entity] name];
        if ([@"Disc" isEqualToString:entityName]) {
            NSMutableDictionary* update = nil;
            for (NSString* key in [managedObject changedValues]) {
                if (![key isEqualToString:@"discMovie"]) {
                    id value = [managedObject valueForKey:key];
                    if (!value) {
                        value = [NSNull null];
                    }
                    if (!update) {
                        update = [NSMutableDictionary dictionaryWithObject:value forKey:key];
                    } else {
                        [update setValue:value forKey:key];
                    }
                }
            }
            if (update) {
                NSString* fingerprint = [managedObject valueForKey:@"com_discident_fingerprint"];
                NSString* uuid = [[managedObject valueForKey:@"movieEngine"] valueForKey:@"UUID"];
                
                NSMutableDictionary* existingUpdates = [updatesByFingerprint objectForKey:fingerprint];
                if (!existingUpdates) {
                    [update setObject:fingerprint forKey:@"com_discident_fingerprint"];
                    [updatesByFingerprint setObject:update forKey:fingerprint];
                } else {
                    [existingUpdates addEntriesFromDictionary:update];
                }
                
                NSMutableSet* setOfFingerprints = [setsOfFingerprintsForEngineControllerByUUID objectForKey:uuid];
                if (!setOfFingerprints) {
                    [setsOfFingerprintsForEngineControllerByUUID setObject:[NSMutableSet setWithObject:fingerprint] forKey:uuid];
                } else {
                    [setOfFingerprints addObject:fingerprint];
                }
            }
        } else if ([@"Movie" isEqualToString:entityName]) {
            NSMutableDictionary* update = nil;
            for (NSString* key in [managedObject changedValues]) {
                if (![key isEqualToString:@"movieEngine"] && ![key isEqualToString:@"movieDiscs"]) {
                    id value = [managedObject valueForKey:key];
                    if (!value) {
                        value = [NSNull null];
                    }
                    if (!update) {
                        update = [NSMutableDictionary dictionaryWithObject:value forKey:key];
                    } else {
                        [update setValue:value forKey:key];   
                    }
                }
            }
            if (update) {
                for (NSManagedObject* disc in [managedObject valueForKey:@"movieDiscs"]) {
                    NSString* fingerprint = [disc valueForKey:@"com_discident_fingerprint"];
                    NSString* uuid = [[managedObject valueForKey:@"movieEngine"] valueForKey:@"UUID"];

                    NSMutableDictionary* existingUpdates = [updatesByFingerprint objectForKey:fingerprint];
                    if (!existingUpdates) {
                        [update setObject:fingerprint forKey:@"com_discident_fingerprint"];
                        [updatesByFingerprint setObject:update forKey:fingerprint];
                    } else {
                        [existingUpdates addEntriesFromDictionary:update];
                    }

                    NSMutableSet* setOfFingerprints = [setsOfFingerprintsForEngineControllerByUUID objectForKey:uuid];
                    if (!setOfFingerprints) {
                        [setsOfFingerprintsForEngineControllerByUUID setObject:[NSMutableSet setWithObject:fingerprint] forKey:uuid];
                    } else {
                        [setOfFingerprints addObject:fingerprint];
                    }
                }
            }
        }
    }

    //  Coalesce all of the updates for each engine controller and send them.
    //
    for (NSString* uuid in setsOfFingerprintsForEngineControllerByUUID) {
        [[enginesManager engineByUUIDKey:uuid] sendAMessage:[NSDictionary dictionaryWithObject:[updatesByFingerprint objectsForKeys:[[setsOfFingerprintsForEngineControllerByUUID objectForKey:uuid] allObjects] notFoundMarker:[NSNull null]] forKey:@"update"]];
    }
}

@end
