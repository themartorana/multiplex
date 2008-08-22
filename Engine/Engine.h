#import <Cocoa/Cocoa.h>
#import "LibraryComProtocol.h"

@interface Engine : NSApplication {
	MDQueryRef query;
    int itemsProcessed;
    NSMutableDictionary* moviesByFingerprint;
    
    LibraryComProtocol* protocol; 
}

#pragma mark LibraryComProtocol delegate methods

- (void) engineMessageWasReceived:(NSDictionary*)messageDict;
- (void) volumeDidMount:(NSNotification*)notification;
- (void) volumeWillUnmount:(NSNotification*)notification;

@end
