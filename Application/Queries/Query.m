#import "Query.h"
#import "Query+Private.h"

#pragma mark -
@implementation Query
@synthesize URL;
@synthesize delegate;
@synthesize userInfo;

+ (id) queryWithURL:(NSURL*)url
{
    return [[[Query alloc] initWithURL:url] autorelease];
}

+ (id) queryWithURL:(NSURL*)url delegate:(id)delegate userInfo:(id)userInfo startImmediately:(BOOL)startImmediately
{
    NSAssert(delegate, @"The delegate must not be nil.");
    Query* query = [Query queryWithURL:url];
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
    [response release];
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
@implementation Query (NSURLConnectionDelegate)

- (void) connection:(NSURLConnection*)connection didReceiveResponse:(NSURLResponse*)_response 
{
    response = [_response retain];
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
    [self _fireDidReceiveData:receivedData ofType:[[response allHeaderFields] objectForKey:@"Content-Type"]];
    [receivedData release];
    receivedData = nil;
    [self autorelease];
}

@end

#pragma mark -
@implementation Query (Private)

- (void) _fireDidReceiveData:(NSData*)data ofType:(NSString*)type
{
    if ([delegate respondsToSelector:@selector(query:didReceiveData:ofType:userInfo:)]) {
        @try {
            [delegate query:self didReceiveData:receivedData ofType:type userInfo:userInfo];
        } @catch (id _exception) {
            NSLog(@"%@: Exception during %s -- %@", NSStringFromClass([self class]), __PRETTY_FUNCTION__, _exception);
        }
    }
}

- (void) _fireDidFailWithError:(NSError*)error
{
    if ([delegate respondsToSelector:@selector(query:didFailWithError:userInfo:)]) {
        @try {
            [delegate query:self didFailWithError:error userInfo:userInfo];
        } @catch (id _exception) {
            NSLog(@"%@: Exception during %s -- %@", NSStringFromClass([self class]), __PRETTY_FUNCTION__, _exception);
        }
    }
}

@end
