//
//  InfoPaneFormController.h
//  Multiplex
//
//  Created by David Martorana on 10/6/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@class Movie;
@class InfoPaneDiscsView;
@class BigPlayButtonView;

@interface InfoPaneFormController : NSObject {
    Movie* selectedMovie;
    
    NSColor* labelColor;
    
    IBOutlet WebView* descriptionWebView;
    IBOutlet InfoPaneDiscsView* infoPaneDiscsView;
    
    IBOutlet BigPlayButtonView* bigPlayButtonView;
    
    IBOutlet NSTabView* infoTabView;
    IBOutlet NSTabViewItem* discsTabViewItem;
}

@property (retain) Movie* selectedMovie;
@property (readonly) NSColor* labelColor;

@end
