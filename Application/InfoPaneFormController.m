
#import "InfoPaneFormController.h"
#import "Movie.h"
#import "InfoPaneDiscsView.h"
#import "BigPlayButtonView.h"
#import "VerticalScroller.h"

#import <WebKit/WebKit.h>

@interface NSScrollView (NSScrollViewWebKitPrivate)
- (void) setAllowsHorizontalScrolling:(BOOL)allow;
- (void) setHorizontalScrollingModeLocked:(BOOL)locked;
@end

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
    [descriptionWebView setFrameLoadDelegate:self];
    [descriptionWebView setEditable:YES];
    [descriptionWebView setDrawsBackground:NO];
        
    WebPreferences* prefs = [descriptionWebView preferences];
    [prefs setUserStyleSheetEnabled:YES];
    [prefs setUserStyleSheetLocation:[NSURL URLWithString:[[NSBundle mainBundle] pathForResource:@"default" ofType:@"css"]]];
    
    [discsTabView bind:@"selectedMovie" toObject:self withKeyPath:@"selectedMovie" options:nil];
}

- (void) setSelectedMovies:(NSArray*)_selectedMovies
{
    selectedMovies = _selectedMovies;
    
    if (selectedMovies && [selectedMovies count] > 0) {
        self.selectedMovie = (Movie*)[selectedMovies objectAtIndex:0];
    } else {
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
    } else {
        [[descriptionWebView mainFrame] loadHTMLString:@"" baseURL:url];
    }
}

- (void) webView:(WebView*)sender didFinishLoadForFrame:(WebFrame*)frame
{
    if (sender != descriptionWebView) {
        return;
    }

    NSScrollView* scrollView = [[[[descriptionWebView mainFrame] frameView] documentView] enclosingScrollView];
    
    VerticalScroller* scroller = (VerticalScroller*)[scrollView verticalScroller];
    if (![scroller isMemberOfClass:[VerticalScroller class]]) {
        NSRect scrollerFrame = [[scrollView verticalScroller] frame];
        NSScroller* oldScroller = scroller;
        scroller = [[[VerticalScroller alloc] initWithFrame:scrollerFrame] autorelease];
        [scroller setFloatValue:[oldScroller floatValue] knobProportion:[oldScroller knobProportion]];
        [scrollView setVerticalScroller:scroller];
    }
}

- (void) webViewDidEndEditing:(NSNotification*)notification
{
    NSString* content = [(id)[[[[[descriptionWebView mainFrame] DOMDocument] documentElement] getElementsByTagName:@"body"] item:0] innerHTML];
    selectedMovie.review = content;
}

- (void) tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    if (tabViewItem == discsTabViewItem) {
        [bigPlayButtonView setHidden:YES];
    } else {
        [bigPlayButtonView setHidden:NO];
    }
}

@end
