#import <Cocoa/Cocoa.h>

@interface ApplicationResources : NSObject {
}

+ (CGImageRef) CGImageFromPDF:(NSString*)path;

+ (CGImageRef) playButton;
+ (CGImageRef) playButtonDown;
+ (CGImageRef) playButtonInactive;
+ (CGImageRef) closeButton;
+ (CGImageRef) closeButtonDown; 

@end
