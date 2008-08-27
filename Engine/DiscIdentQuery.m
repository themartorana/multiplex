#import "DiscIdentQuery.h"
#import "JSONKit/JSONKit.h"

NSString* const kDISC_IDENT_VERSION = @"v1";

@interface DiscIdentQuery (NSURLConnectionDelegate)
- (void) connection:(NSURLConnection*)connection didReceiveResponse:(NSURLResponse*)response;
- (void) connection:(NSURLConnection*)connection didReceiveData:(NSData*)data;
- (void) connection:(NSURLConnection*)connection didFailWithError:(NSError*)error; 
- (void) connectionDidFinishLoading:(NSURLConnection*)connection; 
@end

@interface DiscIdentQuery (Private)
- (void) _fireDidFailWithError:(NSError*)error;
- (void) _fireDidReceiveResponse:(NSDictionary*)response;
@end

@implementation DiscIdentQuery
@synthesize delegate;

+ (id) queryWithFingerprint:(NSString*)fingerprint
{
    return [[[DiscIdentQuery alloc] initWithFingerprint:fingerprint] autorelease];
}

+ (id) queryWithFingerprint:(NSString*)fingerprint delegate:(id)delegate startImmediately:(BOOL)startImmediately
{
    NSAssert(delegate, @"The delegate must not be nil.");
    DiscIdentQuery* query = [DiscIdentQuery queryWithFingerprint:fingerprint];
    query.delegate = delegate;
    if (startImmediately) {
        [query start];
    }
    return query;
}

- (id) initWithFingerprint:(NSString*)fingerprint
{
    if (self = [super init]) {
        request = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://discident.com/%@/%@/", kDISC_IDENT_VERSION, fingerprint]]];
    }
    return self;
}

- (void) dealloc
{
    [connection release];
    [request release];
    [receivedData release];
    [super dealloc];
}

- (void) start
{
    NSAssert(!connection, @"This query has already been started.");
    connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
}

- (void) cancel
{
    [connection cancel];
}

@end

@implementation DiscIdentQuery (NSURLConnectionDelegate)

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
    if ([delegate respondsToSelector:@selector(discIdentQuery:didFailWithError:)]) {
        [delegate discIdentQuery:self didFailWithError:error];
    }
}

- (void) connectionDidFinishLoading:(NSURLConnection *)connection 
{
    NSDictionary* response = nil;
    id exception = nil;
    if ([receivedData length] > 0) {
        @try {
            response = [NSDictionary dictionaryWithJSON:[[[NSString alloc] initWithData:receivedData encoding:NSUTF8StringEncoding] autorelease]];
        } @catch (id _exception) {
            exception = _exception;
        }
    }

    if (!response || exception) {
        [self _fireDidFailWithError:nil];
    } else {
        [self _fireDidReceiveResponse: response];

    }
}

@end

@implementation DiscIdentQuery (Private)

- (void) _fireDidFailWithError:(NSError*)error
{
    if ([delegate respondsToSelector:@selector(discIdentQuery:didFailWithError:)]) {
        @try {
            [delegate discIdentQuery:self didFailWithError:error];
        } @catch (id _exception) {
            NSLog(@"DiscIdentQuery: Exception during discIdentQuery:didFailWithError: -- %@", _exception);
        }
    }
}

- (void) _fireDidReceiveResponse:(NSDictionary*)response  
{
    if ([delegate respondsToSelector:@selector(discIdentQuery:didReceiveResponse:)]) {
        @try {
            [delegate discIdentQuery:self didReceiveResponse:response];
        } @catch (id _exception) {
            NSLog(@"DiscIdentQuery: Exception during discIdentQuery:didReceiveResponse: -- %@", _exception);
        }
    }
}

@end
