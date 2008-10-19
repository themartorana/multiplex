//
//  UserVoiceFeedbackPanel.m
//  Multiplex
//
//  Created by David Martorana on 10/19/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "UserVoiceFeedbackPanel.h"
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

    WebPreferences* prefs = [userVoiceFeedbackWebView preferences];
    [prefs setUserStyleSheetEnabled:YES];
    [prefs setUserStyleSheetLocation:[NSURL URLWithString:[[NSBundle mainBundle] pathForResource:@"uservoice-feedback" ofType:@"css"]]];   
    
    [self resetFeedbackPage];
}

- (void) resetFeedbackPage
{
    [userVoiceFeedbackWebView setMainFrameURL:@"http://multiplex.uservoice.com/pages/beta/widgets/popin.html?referer=org.indyhall.labs.multiplex"];
}

- (IBAction) closeSheet:(id)sender
{
    [NSApp endSheet:(NSWindow*)self];
}

- (void)webView:(WebView *)sender decidePolicyForNewWindowAction:(NSDictionary *)actionInformation request:(NSURLRequest *)request newFrameName:(NSString *)frameName decisionListener:(id < WebPolicyDecisionListener >)listener
{
    [[NSWorkspace sharedWorkspace] openURL:[request URL]];
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
    // We only have one frame
}


@end
