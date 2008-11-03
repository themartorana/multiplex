#import <Cocoa/Cocoa.h>

@class CATextLayer;

@interface TextView : NSView {
    CATextLayer* textLayer;
    
    NSString* text;
}

@property (retain) NSString* text;

- (void) setHasShadow:(BOOL)_hasShadow;
- (void) setBackgroundColor:(CGColorRef)_color;
- (void) setForegroundColor:(CGColorRef)_color;

@end
