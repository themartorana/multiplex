#import <Cocoa/Cocoa.h>

@class WebPreferences;

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

+ (CGImageRef) textureForStadiumLayoutFloor;
+ (CGImageRef) textureForDrawerBackground;
+ (CGImageRef) textureForDrawerTopEdge;

+ (WebPreferences*) movieDescriptionWebPreferences;
+ (WebPreferences*) userVoiceWebPreferences;

@end
