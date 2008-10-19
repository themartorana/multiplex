//
//  UserVoiceFeedbackPanel.h
//  Multiplex
//
//  Created by David Martorana on 10/19/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class WebView;

@interface UserVoiceFeedbackPanel : NSPanel {
    IBOutlet WebView* userVoiceFeedbackWebView;
}

- (IBAction) closeSheet:(id)sender;

- (void) resetFeedbackPage;

@end
