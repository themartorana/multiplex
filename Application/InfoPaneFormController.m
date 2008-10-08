//
//  InfoPaneFormController.m
//  Multiplex
//
//  Created by David Martorana on 10/6/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "InfoPaneFormController.h"
#import "Movie.h"
#import <WebKit/WebKit.h>


@implementation InfoPaneFormController

@synthesize selectedMovies;
@synthesize selectedMovie;
@synthesize labelColor;

- (InfoPaneFormController*) init
{
    if (self = [super init]) {
        labelColor = [NSColor colorWithCalibratedRed:231.0/255.0 green:111.0/255.0 blue:52.0/255.0 alpha:1.0];
    }
    
    return self;
}

- (void) awakeFromNib
{
    // Set up the appropriate things for the web view
    [descriptionWebView setEditingDelegate:self];
    [descriptionWebView setEditable:YES];
}

- (void) setSelectedMovies:(NSArray*)_selectedMovies
{
    selectedMovies = _selectedMovies;
    
    if (selectedMovies && [selectedMovies count] > 0) {
        self.selectedMovie = (Movie*)[selectedMovies objectAtIndex:0];
    }
    else {
        self.selectedMovie = nil;
    }
}

- (void) setSelectedMovie:(Movie*)_movie
{
    selectedMovie = _movie;
    NSURL* url = [NSURL URLWithString:@""];
    
    if (selectedMovie) {
        // Send to web kit
        [[descriptionWebView mainFrame] loadHTMLString:selectedMovie.review baseURL:url];
    }
    else {
        [[descriptionWebView mainFrame] loadHTMLString:@"" baseURL:url];
    }
}

- (void) webViewDidEndEditing:(NSNotification*)notification
{
    NSString* content = [(id)[[[[[descriptionWebView mainFrame] DOMDocument] documentElement] getElementsByTagName:@"body"] item:0] innerHTML];
    selectedMovie.review = content;
}

@end
