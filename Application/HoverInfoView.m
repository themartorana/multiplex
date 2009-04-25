#import "HoverInfoView.h"
#import <WebKit/WebKit.h>
#import "Movie.h"
#import "ApplicationResources.h"
#import "MainView.h"
#import "MultiplexColorFactory.h"

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
    [webView setUIDelegate:self];

    //[self setWantsLayer:YES];
    //[[self layer] setBackgroundColor:[MultiplexColorFactory whiteOneQuarterTransparent]];
    
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
        
        int height = [[[frame DOMDocument] getElementById:@"hoverview"] offsetHeight];
        int width = [[[frame DOMDocument] getElementById:@"hoverview"] offsetWidth];
        
        int yOffset = 52.0;
        if ([movie.availableDiscCount intValue] > 0) {
            // In this case, we're adding the extra "Play" link line
            yOffset += 17.0;
        }
        
        [self setFrame:NSMakeRect([self frame].origin.x, 
                                  [self frame].origin.y - yOffset, 
                                  //[self frame].size.width, 
								  width,
								  height)]; 
                                  //height + 20.0 + 5.0)];
    }
    
    [super setHidden:NO];
}

- (NSArray *)webView:(WebView *)sender contextMenuItemsForElement:(NSDictionary *)element defaultMenuItems:(NSArray *)defaultMenuItems
{
    return [NSArray array];
}

- (void) setHidden:(BOOL)hidden
{
    if (!hidden && movie) {
        NSPoint mousePoint = [[self window] mouseLocationOutsideOfEventStream];
        NSPoint positionOfMouse = [[self superview] convertPoint:mousePoint fromView:nil];
        
		int xoffset = 10;
		int yoffset = -20;
		
        int newx = positionOfMouse.x + xoffset;
        int newy = positionOfMouse.y + yoffset;
        
        if (inFlipPosition) {
            newx -= [self bounds].size.width + (2*xoffset);
        }

        [self setFrame:NSMakeRect(newx, 
                                  newy, 
                                  [self bounds].size.width, 
                                  [self bounds].size.height)];
        
        // Load up the html
        NSString* htmlString = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"hoverview" ofType:@"html"]];
        
        // Replace
        if (!inFlipPosition) {
            htmlString = [htmlString stringByReplacingOccurrencesOfString:@"<!--[POINTER-ID]-->" withString:@"pointer-left"];
        }
        else {
            htmlString = [htmlString stringByReplacingOccurrencesOfString:@"<!--[POINTER-ID]-->" withString:@"pointer-right"];
        }
        
        if (movie.title) {
            htmlString = [htmlString stringByReplacingOccurrencesOfString:@"<!--[TITLE]-->" withString:movie.title];
        }
        if (movie.runningTime && [movie.runningTime intValue] > 0) {
            htmlString = [htmlString stringByReplacingOccurrencesOfString:@"<!--[TIME]-->" withString:[NSString stringWithFormat:@"%@ %@", [movie.runningTime stringValue], NSLocalizedString(@"minutes", nil)]];
        }
        if (movie.rating) {
            htmlString = [htmlString stringByReplacingOccurrencesOfString:@"<!--[RATING]-->" withString:movie.rating];
        }
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
