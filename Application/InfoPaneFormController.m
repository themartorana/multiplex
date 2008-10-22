
#import "InfoPaneFormController.h"
#import "Movie.h"
#import "InfoPaneDiscsView.h"
#import "MultiplexColorFactory.h"

#import <WebKit/WebKit.h>

@interface NSScrollView (NSScrollViewWebKitPrivate)
- (void) setAllowsHorizontalScrolling:(BOOL)allow;
- (void) setHorizontalScrollingModeLocked:(BOOL)locked;
@end

@implementation InfoPaneFormController

@synthesize movie;
@synthesize labelColor;

- (InfoPaneFormController*) init
{
    if (self = [super init]) {
        labelColor = [MultiplexColorFactory multiplexYellowOrange];
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
}

- (void) setMovie:(Movie*)_selectedMovie
{
    if (movie != _selectedMovie) {
        [movie release];
        movie = [_selectedMovie retain];
    }
    NSURL* url = [NSURL URLWithString:@""];
    
    if (movie) {
        // Send to web kit
        [[descriptionWebView mainFrame] loadHTMLString:movie.review baseURL:url];
    } else {
        [[descriptionWebView mainFrame] loadHTMLString:@"" baseURL:url];
    }
}

- (void) webViewDidEndEditing:(NSNotification*)notification
{
    NSString* content = [(id)[[[[[descriptionWebView mainFrame] DOMDocument] documentElement] getElementsByTagName:@"body"] item:0] innerHTML];
    movie.review = content;
}

- (void) tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
#if 0
    if (tabViewItem == discsTabViewItem) {
        [bigPlayButtonView setHidden:YES];
    } else {
        [bigPlayButtonView setHidden:NO];
    }
#endif
}

- (void) showHomeTab
{
    [infoTabView selectTabViewItem:[[infoTabView tabViewItems] objectAtIndex:0]];
}

- (void) showDiscsTab
{
    [infoTabView selectTabViewItem:discsTabViewItem];
}

@end
