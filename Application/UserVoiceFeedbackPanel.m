#import "UserVoiceFeedbackPanel.h"
#import "ApplicationResources.h"
#import <WebKit/WebKit.h>

@implementation UserVoiceFeedbackPanel

- (void) awakeFromNib
{
    [self setOpaque:NO];
    [self setBackgroundColor:[NSColor colorWithCalibratedRed:0.0 
                                                       green:0.0 
                                                        blue:0.0 
                                                       alpha:0.5]];
    [userVoiceFeedbackWebView setDrawsBackground:NO];
    [userVoiceFeedbackWebView setFrameLoadDelegate:self];
    [userVoiceFeedbackWebView setPolicyDelegate:self];

    id style = [userVoiceFeedbackWebView styleDeclarationWithText:[NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"uservoice-feedback" ofType:@"css"]]];
    [userVoiceFeedbackWebView applyStyle:style];

    [userVoiceFeedbackWebView setPreferences:[ApplicationResources userVoiceWebPreferences]];
    
    [self resetFeedbackPage];
}

- (void) resetFeedbackPage
{
    [userVoiceFeedbackWebView setMainFrameURL:@"http://multiplex.uservoice.com/pages/4657-multiplex/widgets/popin.html?referer=org.indyhall.labs.multiplex"];
}

- (IBAction) closeSheet:(id)sender
{
    [NSApp endSheet:self];
}

- (void) webView:(WebView*)sender decidePolicyForNewWindowAction:(NSDictionary*)actionInformation request:(NSURLRequest*)request newFrameName:(NSString*)frameName decisionListener:(id<WebPolicyDecisionListener>)listener
{
    [[NSWorkspace sharedWorkspace] openURL:[request URL]];
}

- (void) webView:(WebView*)sender didFinishLoadForFrame:(WebFrame *)frame
{
}


@end

