#import "MovieLayer.h"
#import "Movie.h"
#import "Disc.h"
#import "Media.h"

@implementation MovieLayer

@synthesize movie;

- (void) setMovie:(Movie*)_movie {
    movie = _movie;
    
    BOOL fullBreak = false;
    
    // Look for the first instance of a cover
    NSArray* discs = [movie.allDiscs allObjects];

    for (Disc* disc in discs) {
        NSArray* discMedia = [disc.allMedia allObjects];

        for (Media* media in discMedia) {
            if (media.url && [media.url length] > 0) {
                
                NSString* url = [[media.url stringByAppendingPathComponent:@"QuickLook"] stringByAppendingPathComponent:@"FrontCover.png"];
                url = [url stringByReplacingOccurrencesOfString:@"file:/localhost/" withString:@"file:///"];
                NSLog(@"%@", url);
                
                // Call out to it.
                NSURL* imageURL = [NSURL URLWithString:url];
                NSURLRequest* request = [NSURLRequest requestWithURL:imageURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:5.0];
                
                if ([NSURLConnection canHandleRequest:request]) {
                    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
                    if(connection) {
                        imageData = [[NSMutableData data] retain];
                    }
                    
                    fullBreak = YES;
                    break;
                }
            }
        }
        
        if (fullBreak) {
            break;
        }        
    }
}

#pragma mark NSURLConnection Delegate Methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [imageData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError*)error
{
    [imageData release];
    NSLog(@"Connection error: %@", error);
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [imageData appendData:data];
}


- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    CIImage *downloadedImage = [CIImage imageWithData:imageData];
    CIContext* ciContext = [[[NSApp mainWindow] graphicsContext] CIContext];
    CGImageRef iref = [ciContext createCGImage:downloadedImage fromRect:[downloadedImage extent]];
    
    [self setContents:(id)iref];
    
    CGImageRelease(iref);
    [imageData release];
    [connection release];
}


@end
