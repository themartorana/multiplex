#import <Cocoa/Cocoa.h>

@class WebView;

@interface UserVoiceFeedbackPanel : NSPanel {
    IBOutlet WebView* userVoiceFeedbackWebView;
}

- (IBAction) closeSheet:(id)sender;

- (void) resetFeedbackPage;

@end
