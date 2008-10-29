#import <Cocoa/Cocoa.h>

@interface DrawerView : NSView {
    IBOutlet NSView* upperView;
    IBOutlet NSView* contentView;
    IBOutlet NSView* button;
    CGFloat minHeight;
    BOOL isOpen;
}

@property BOOL isOpen;
@property (retain) NSView* contentView;
@property (readonly) NSView* upperView;

- (IBAction) toggle:(id)sender;

- (void) openDrawer;
- (void) closeDrawer;

@end
