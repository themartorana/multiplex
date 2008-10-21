#import <Cocoa/Cocoa.h>

@class MainView;
@class HoverTitleView;
@class InfoPaneFormController;
@class UserVoiceFeedbackPanel;

@interface WindowController : NSWindowController {
    IBOutlet NSArrayController* movies;
    IBOutlet MainView* mainView;
    
    IBOutlet HoverTitleView* hoverTitleView;
    IBOutlet NSView* infoPaneView;
    IBOutlet NSView* searchView;
    
    IBOutlet InfoPaneFormController* infoPaneFormController;
    
    IBOutlet UserVoiceFeedbackPanel* userVoiceFeedbackPanel;
}

- (IBAction) showUserVoiceFeedbackSheet:(id)sender;
- (IBAction) toggleDrawerView:(id)sender;

@end
