#import <Cocoa/Cocoa.h>

@class Item;

@interface Movie : NSObject {
	NSString* fingerprint;
    NSMutableArray* items;
    
    BOOL listenForLoopback;
}

@property (readwrite) BOOL listenForLoopback;

- (id) initWithItem:(Item*)item;

- (NSString*) contentType;
- (NSString*) fingerprint;
- (BOOL) hasItem;
- (NSString*) pathToFile;
- (BOOL) isPhysicalMedia;

- (void) addItem:(Item*)item;
- (void) removeItem:(Item*)item;

@end
