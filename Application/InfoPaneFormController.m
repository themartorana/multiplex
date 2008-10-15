
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

@synthesize selectedMovie;
@synthesize selectedMovies;
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
    
    NSDictionary* options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:NSAllowsNullArgumentBindingOption];
    [infoPaneDiscsView bind:@"selectedMovie" toObject:self withKeyPath:@"selectedMovie" options:options];
}

- (void) setSelectedMovies:(NSArray*)_selectedMovies
{
    if (selectedMovies != _selectedMovies) {
        [selectedMovies release];
        selectedMovies = [_selectedMovies retain];
    }
    
    if (selectedMovies && [selectedMovies count] > 0) {
        [self setSelectedMovie:(Movie*)[selectedMovies objectAtIndex:0]];
    } else {
        [self setSelectedMovie:nil];
    }
}

- (void) setSelectedMovie:(Movie*)_selectedMovie
{
    if (selectedMovie != _selectedMovie) {
        [selectedMovie release];
        selectedMovie = [_selectedMovie retain];
    }
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
