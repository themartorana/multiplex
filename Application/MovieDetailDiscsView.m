#import "MovieDetailDiscsView.h"
#import "Movie.h"
#import "Disc.h"
#import "Media.h"
#import "MultiplexColorFactory.h"
#import "ApplicationResources.h"
#import "MovieDetailController.h"

#import <Toolkit/Toolkit.h>
#import <JSONKit/JSONKit.h>

@interface MovieDetailDiscsView (Private)

- (void) _setUpDiscLayers;

@end

@implementation MovieDetailDiscsView (JavascriptHooks)

+ (BOOL) isSelectorExcludedFromWebScript:(SEL)selector {
    if (selector == @selector(signalIsReady)) {
        return NO;
    }
    if (selector == @selector(playDisc:)) {
        return NO;
    }
    return YES;
}

+ (NSString*) webScriptNameForSelector:(SEL)sel
{
    if (sel == @selector(playDisc:))
        return @"playDisc";
    return nil;
}

@end


@implementation MovieDetailDiscsView

@synthesize movie;
@synthesize isReady;

- (void) awakeFromNib
{
    [webView setDrawsBackground:NO];
    [webView setPreferences:[ApplicationResources discsViewWebPreferences]];
    [webView setFrameLoadDelegate:self];
    [webView setUIDelegate:self];
    
    // Load the initial html
    NSString* html = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"discs-tab" ofType:@"html"]];
    [[webView mainFrame] loadHTMLString:html baseURL:[NSURL URLWithString:@""]];
}

- (void) setMovie:(Movie*)_selectedMovie
{
    if (movie != _selectedMovie) {
        [movie release];
        movie = [_selectedMovie retain];
    }

    if (isReady) {
        [self _setUpDiscLayers];        
    }
}

#pragma mark Private Methods

- (void) _setUpDiscLayers
{
    NSMutableDictionary* dict = [NSMutableDictionary dictionary];
    NSMutableArray* arr = [NSMutableArray array];
    
    // Loop the discs
    for (Disc* disc in [movie.allDiscs allObjects]) {
        NSMutableDictionary* discDict = [NSMutableDictionary dictionary];
        [discDict setValue:disc.number forKey:@"number"];
        [discDict setValue:(disc.discTitle ? disc.discTitle : [NSString stringWithFormat:@"Disc %i", [disc.number intValue]]) forKey:@"title"];
        [discDict setValue:disc.synopsis forKey:@"synopsis"];
        [discDict setValue:[NSString stringWithFormat:@"%@", [[[disc objectID] URIRepresentation] absoluteURL]] forKey:@"objectID"];

        BOOL isDVD = YES;
        for (Media* m in [disc.allMedia allObjects]) {
            if (![m.type isEqualToString:@"public.dvdmedia"] && ![m.type isEqualToString:@"SAMPLE_DATA"]) {
                isDVD = NO;
                break;
            }
        }
        [discDict setValue:(isDVD ? @"YES" : @"NO") forKey:@"isDVD"];
        
        [arr addObject:discDict];
    }
    
    [dict setObject:arr forKey:@"discs"];
    
    // Send it to the JS
    id a = [webView windowScriptObject];
    [a callWebScriptMethod:@"resetDiscs" withArguments:[NSArray arrayWithObject:movie]];
}

- (void) signalIsReady
{
    self.isReady = YES;
    if (self.movie) {
        [self _setUpDiscLayers];
    }
}

- (void) playDisc:(id)disc
{
    [movieDetailController playDisc:disc];
}

#pragma mark WebFrameLoadDelegate Methods

- (void)webView:(WebView *)sender didClearWindowObject:(WebScriptObject *)windowObject forFrame:(WebFrame *)frame
{
    // The Javscript is ready
    [windowObject setValue:self forKey:@"mplex"];
}

#pragma mark WebUIDelegate Methods

- (void)webView:(WebView *)sender runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WebFrame *)frame
{
    NSAlert* a = [NSAlert alertWithMessageText:@"Alert" 
                                 defaultButton:@"Ok" 
                               alternateButton:nil 
                                   otherButton:nil 
                     informativeTextWithFormat:message];
    
    [a runModal];
}

@end
