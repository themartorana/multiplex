#import <Cocoa/Cocoa.h>
#import "ApplicationController.h"

@interface MainWindowContentView : NSView {
    IBOutlet ApplicationController* applicationController;
    IBOutlet NSButton* toggleFullScreenButton;
    IBOutlet NSView* mainView;
    IBOutlet NSSearchField* searchField;
    
    
    NSWindow* fswin;
}

- (void) toggleFullScreen;
- (IBAction) toggleFullScreen:(id)sender;

@end
