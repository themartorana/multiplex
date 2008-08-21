//
//  EnginesManager.m
//  Library
//

#import "EnginesManager.h"
#import "EngineController.h"

//  This class will eventually sport an Bonjour listener as 
//  well as just a single engine

@implementation EnginesManager

- (id) init {
    NSException* exception = [NSException exceptionWithName:@"Wrong init method" reason:@"Please use initWithManagedObjectContext:" userInfo:nil];
    [exception raise];

    return nil;
}


- (id) initWithManagedObjectContext:(NSManagedObjectContext*)managedObjectContext {
    if (self = [super init]){
        _engines = [[[NSMutableDictionary alloc] init] retain];
        
        _nsmoc = managedObjectContext;
        
        // Fire up the local engine
        EngineController* ecLocal = [[EngineController alloc] initWithLocalEngine:_nsmoc];
        [_engines setObject:ecLocal forKey:ecLocal.UUID];
    }
    
    return self;
}

///
/// Allow someone to get a pointer to the engine controller
/// via it's UUID key
///
- (EngineController*) engineByUUIDKey:(NSString*)UUIDKey
{
    return [_engines objectForKey:UUIDKey];
}


///
/// Close all our engines
/// 
- (void) closeAllEngines {
    // Loop through and close every engine
    for (int i = 0; i < [[_engines allKeys] count]; i++) {
        [(EngineController*)[_engines objectForKey:[[_engines allKeys] objectAtIndex:i]] close];
        [_engines removeObjectForKey:[[_engines allKeys] objectAtIndex:i]];
    }
}


- (void) dealloc {
    [self closeAllEngines];
    
    [_engines release];
    [_nsmoc release];
    
    [super dealloc];
}

@end
