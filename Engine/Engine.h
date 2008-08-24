#import <Cocoa/Cocoa.h>
#import "LibraryComProtocol.h"
#import "MediaSource.h"

@interface Engine : NSApplication <MediaSourceDelegate> {
    NSMutableDictionary* infoDictionariesByFingerprint;
    NSMutableDictionary* moviesByFingerprint;
    LibraryComProtocol* protocol; 
}

#pragma mark LibraryComProtocol delegate methods

- (void) engineMessageWasReceived:(NSDictionary*)messageDict;

@end
