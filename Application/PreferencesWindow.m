//
//  Preferences.m
//  Multiplex
//
//  Created by David Martorana on 2/6/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PreferencesWindow.h"


@implementation PreferencesWindow

- (void) awakeFromNib
{
    [self center];
}

- (void) keyDown: (NSEvent *) event
{
    [super keyDown:event];
    if ([event keyCode] == 53) /* ESC */ {
        [self close];
    }
}

- (void) close
{
    [self makeFirstResponder:nil];  //  Essentially saves preferences
    [super close];
}

@end
