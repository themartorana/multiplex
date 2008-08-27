#import <Cocoa/Cocoa.h>
#import "MessageProtocol.h"
#import "MediaSource.h"

@interface Engine : NSApplication <MediaSourceDelegate> {
    NSMutableDictionary* infoDictionariesByFingerprint;
    NSMutableDictionary* discsByFingerprint;
    MessageProtocol* protocol; 
}

@end
