#import "HoverInfoView.h"
#import <WebKit/WebKit.h>
#import "Movie.h"
#import "ApplicationResources.h"
#import "MainView.h"

NSString* const URL_PREFIX = @"multiplex://";

@implementation HoverInfoView

@synthesize movie;
@synthesize inFlipPosition;

- (void) awakeFromNib
{
    // Set up the web view
    [webView setDrawsBackground:NO];
    [webView setPreferences:[ApplicationResources hoverViewWebPreferences]];    
    
    [webView setFrameLoadDelegate:self];
    [webView setPolicyDelegate:self];
    
    inFlipPosition = NO;
}

- (void) setMovie:(Movie*)_movie
{
    [self willChangeValueForKey:@"movie"];
    [movie release];
    movie = nil;
    movie = [_movie retain];
    [self didChangeValueForKey:@"movie"];
}

- (void)webView:(WebView *)sender decidePolicyForNavigationAction:(NSDictionary *)actionInformation request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id < WebPolicyDecisionListener >)listener
{
    NSLog(@"request url: %@", [request URL]);
    NSString* urlString = [[[request URL] absoluteString] stringByReplacingOccurrencesOfString:URL_PREFIX withString:@""];
    
    if ([urlString length] > 0) {
        if ([urlString isEqualToString:@"OPEN_MOVIE"]) {
            [self setHidden:YES];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"MultiplexShowMovieDialog" object:movie];
        }
        else if ([urlString isEqualToString:@"PLAY_MOVIE"]) {
            [self setHidden:YES];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"MultiplexPlayMovie" object:movie];
        }
    }
    
    [listener ignore];
}

- (void) webView:(WebView*)sender didFinishLoadForFrame:(WebFrame *)frame
{
    if (frame == [webView mainFrame]) {
        int height = [[[frame frameView] documentView] frame].size.height;
        [self setBounds:NSMakeRect(0, 0, [self frame].size.width, height)];
    }
    
    [super setHidden:NO];
}

- (void) setHidden:(BOOL)hidden
{
    if (!hidden && movie) {
        NSPoint mousePoint = [[self window] mouseLocationOutsideOfEventStream];
        NSPoint positionOfMouse = [[self superview] convertPoint:mousePoint fromView:nil];
                
        int newx = positionOfMouse.x;
        int newy = positionOfMouse.y - [self bounds].size.height;
        
        if (inFlipPosition) {
            newx -= [self bounds].size.width;
        }

        [self setFrame:NSMakeRect(newx, 
                                  newy, 
                                  [self bounds].size.width, 
                                  [self bounds].size.height)];
        
        // Load up the html
        NSString* htmlString = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"hoverview" ofType:@"html"]];
        
        // Replace
        if (movie.title) {
            htmlString = [htmlString stringByReplacingOccurrencesOfString:@"<!--[TITLE]-->" withString:movie.title];
        }
        if (movie.runningTime && [movie.runningTime intValue] > 0) {
            htmlString = [htmlString stringByReplacingOccurrencesOfString:@"<!--[TIME]-->" withString:[NSString stringWithFormat:@"%@ %@", [movie.runningTime stringValue], NSLocalizedString(@"minutes", nil)]];
        }
        if (movie.rating) {
            htmlString = [htmlString stringByReplacingOccurrencesOfString:@"<!--[RATING]-->" withString:movie.rating];
        }
        NSLog(@"Available disc count: %i", movie.availableDiscCount);
        if ([movie.availableDiscCount intValue] > 0) {
            htmlString = [[htmlString stringByReplacingOccurrencesOfString:@"<!--[PLAY_MOVIE]" withString:@""] 
                          stringByReplacingOccurrencesOfString:@"[PLAY_MOVIE]-->"
                          withString:@""
                          ];
        }
        
        // Set our webview with the content
        WebFrame* mainFrame = [webView mainFrame];
        [mainFrame loadHTMLString:htmlString baseURL:[NSURL URLWithString:@""]];
    }
    else {
        [super setHidden:YES];
    }
}

@end
