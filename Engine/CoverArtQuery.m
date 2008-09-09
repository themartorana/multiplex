#import "CoverArtQuery.h"

#pragma mark -
@interface CoverArtQuery (Private)
- (void) _fireDidFailWithError:(NSError*)error;
- (void) _fireDidReceiveResponse:(NSImage*)response;
@end

#pragma mark -
@implementation CoverArtQuery
@synthesize delegate;
@synthesize URL;
@synthesize userInfo;

+ (id) queryWithURL:(NSURL*)url
{
    return [[[CoverArtQuery alloc] initWithURL:url] autorelease];
}

+ (id) queryWithURL:(NSURL*)url delegate:(id)delegate userInfo:(void*)userInfo startImmediately:(BOOL)startImmediately
{
    NSAssert(delegate, @"The delegate must not be nil.");
    CoverArtQuery* query = [CoverArtQuery queryWithURL:url];
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
    [super dealloc];
}

- (void) start
{
    NSAssert(!connection, @"This query has already been started.");
    request = [[NSURLRequest requestWithURL:URL] retain];
    connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
}

- (void) cancel
{
    [connection cancel];
}

@end

#pragma mark -
@implementation CoverArtQuery (NSURLConnectionDelegate)

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
}

- (void) connectionDidFinishLoading:(NSURLConnection *)connection 
{
    NSImage* response = nil;
    NSError* error = nil;
    if ([receivedData length] > 0) {
        response = [[[NSImage alloc] initWithData:receivedData] autorelease];
    }
    
    if (!response || error) {
        [self _fireDidFailWithError:error];
    } else {
        [self _fireDidReceiveResponse:response];
    }
}

@end

#pragma mark -
@implementation CoverArtQuery (Private)

- (void) _fireDidFailWithError:(NSError*)error
{
    if ([delegate respondsToSelector:@selector(coverArtQuery:didFailWithError:userInfo:)]) {
        @try {
            [delegate coverArtQuery:self didFailWithError:error userInfo:userInfo];
        } @catch (id _exception) {
            NSLog(@"CoverArtQuery: Exception during coverArtQuery:didFailWithError: -- %@", _exception);
        }
    }
}

- (void) _fireDidReceiveResponse:(NSImage*)response  
{
    if ([delegate respondsToSelector:@selector(coverArtQuery:didReceiveResponse:userInfo:)]) {
        @try {
            [delegate coverArtQuery:self didReceiveResponse:response userInfo:userInfo];
        } @catch (id _exception) {
            NSLog(@"CoverArtQuery: Exception during coverArtQuery:didReceiveResponse: -- %@", _exception);
        }
    }
}

@end
