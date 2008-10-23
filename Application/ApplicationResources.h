#import <Cocoa/Cocoa.h>

@interface ApplicationResources : NSObject {
}

+ (CGImageRef) CGImageFromFileAtPath:(NSString*)path;
+ (CGImageRef) CGImageFromResource:(NSString*)name ofType:(NSString*)type;

+ (CGImageRef) editIcon;
+ (CGImageRef) playButton;
+ (CGImageRef) playButtonDown;
+ (CGImageRef) playButtonInactive;
+ (CGImageRef) closeButton;
+ (CGImageRef) closeButtonDown; 

@end
