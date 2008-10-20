#import "ImageQuery.h"

#pragma mark -
@interface ImageQuery (Private)
- (void) _fireDidFailWithError:(NSError*)error;
@end

#pragma mark -
@implementation ImageQuery
@synthesize delegate;
@synthesize URL;
@synthesize userInfo;

+ (id) imageQueryWithURL:(NSURL*)url
{
    return [[[ImageQuery alloc] initWithURL:url] autorelease];
}

+ (id) imageQueryWithURL:(NSURL*)url delegate:(id)delegate userInfo:(id)userInfo startImmediately:(BOOL)startImmediately
{
    NSAssert(delegate, @"The delegate must not be nil.");
    ImageQuery* query = [ImageQuery imageQueryWithURL:url];
    query.delegate = delegate;
    query.userInfo = userInfo;
    if (startImmediately) {
        [query start];
    }
    return query;
}

- (id) initWithURL:(NSURL*)_url
{
    NSAssert(_url, @"url must not be nil.");
    if (self = [super init]) {
        URL = [_url retain];
    }
    return self;
}

- (void) dealloc
{
    [URL release];
    [connection release];
    [request release];
    [receivedData release];
    [userInfo release];
    [super dealloc];
}

- (void) start
{
    NSAssert(!connection, @"This query has already been started.");
    request = [[NSMutableURLRequest requestWithURL:URL] retain];
    [request setTimeoutInterval:5.0];
    connection = [[NSURLConnection alloc] initWithRequest:request delegate:[self retain] startImmediately:YES];
}

- (void) cancel
{
    [connection cancel];
}

@end

#pragma mark -
@implementation ImageQuery (NSURLConnectionDelegate)

- (void) connection:(NSURLConnection*)connection didReceiveResponse:(NSURLResponse*)response 
{
    receivedData = [[NSMutableData alloc] init];
}

- (void) connection:(NSURLConnection*)connection didReceiveData:(NSData*)data 
{
    [receivedData appendData:data];
}

- (void) connection:(NSURLConnection*)connection didFailWithError:(NSError*)error 
{
    [receivedData release];
    receivedData = nil;
    [self _fireDidFailWithError:error];
    [self autorelease];
}

- (void) connectionDidFinishLoading:(NSURLConnection *)connection 
{
    if (![receivedData length]) {
        [self _fireDidFailWithError:nil];
        return;
    }

    if ([delegate respondsToSelector:@selector(imageQuery:didReceiveImage:userInfo:)]) {
        NSImage* image = nil;
        @try {
            image = [[NSImage alloc] initWithData:receivedData];
            [delegate imageQuery:self didReceiveImage:image userInfo:userInfo];
        } @catch (id _exception) {
            NSLog(@"CoverArtQuery: Exception during coverArtQuery:didReceiveImage: -- %@", _exception);
        }
        [image release];
    }
    
    if ([delegate respondsToSelector:@selector(imageQuery:didReceiveImageSource:userInfo:)]) {
        CGImageSourceRef imageSource = CGImageSourceCreateWithData((CFDataRef)receivedData, nil);
        if (imageSource) {
            @try {
                [delegate imageQuery:self didReceiveImageSource:imageSource userInfo:userInfo];
            } @catch (id _exception) {
                NSLog(@"CoverArtQuery: Exception during coverArtQuery:didReceiveImageSource: -- %@", _exception);
            }
            CFRelease(imageSource);
        }
    }

    [receivedData release];
    receivedData = nil;
    [self autorelease];
}

@end

#pragma mark -
@implementation ImageQuery (Private)

- (void) _fireDidFailWithError:(NSError*)error
{
    if ([delegate respondsToSelector:@selector(imageQuery:didFailWithError:userInfo:)]) {
        @try {
            [delegate imageQuery:self didFailWithError:error userInfo:userInfo];
        } @catch (id _exception) {
            NSLog(@"CoverArtQuery: Exception during coverArtQuery:didFailWithError: -- %@", _exception);
        }
    }
}

@end
