#import <Cocoa/Cocoa.h>

@class Item;

@interface Movie : NSObject {
	NSString* fingerprint;
    NSMutableArray* items;
}

- (id) initWithItem:(Item*)item;

- (NSString*) contentType;
- (NSString*) fingerprint;
- (BOOL) hasItem;
- (NSString*) pathToFile;

- (void) addItem:(Item*)item;
- (void) removeItem:(Item*)item;

@end
