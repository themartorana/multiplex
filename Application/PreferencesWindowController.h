#import <Cocoa/Cocoa.h>

@class ApplicationController;
@class PreferencesWindow;

@interface PreferencesWindowController : NSWindowController {
    IBOutlet NSView* generalView;
    IBOutlet NSView* appearanceView;
    IBOutlet NSView* advancedView;
    
    IBOutlet NSUserDefaults* userDefaults;
    
    ApplicationController* appController;
}

- (id) initWithApplicationController:(ApplicationController*)applicationController;

@end
