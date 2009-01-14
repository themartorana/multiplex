#import "MultiplexResourceURLProtocol.h"


@implementation MultiplexResourceURLProtocol

+ (BOOL) canInitWithRequest:(NSURLRequest*)request
{
    NSString* scheme = [[request URL] scheme];
	return [scheme caseInsensitiveCompare:@"multiplexresource"] == NSOrderedSame;
}

+ (NSURLRequest*) canonicalRequestForRequest:(NSURLRequest*)request
{
    return [NSURLRequest requestWithURL:[[request URL] standardizedURL]];
}

- (void) startLoading
{
    //NSLog(@"%@", [[self request] URL]);
    NSURL *url = [[self request] URL];

    NSString* file = [url host];
    NSData* data = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:file ofType:nil]];
    
    id<NSURLProtocolClient> client = [self client];
	
    if (data) {
		NSURLResponse* response = [[NSURLResponse alloc] initWithURL:url MIMEType:nil expectedContentLength:[data length] textEncodingName:nil];
		[client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
		[client URLProtocol:self didLoadData:data];
		[client URLProtocolDidFinishLoading:self];
	} else {
        [client URLProtocol:self didFailWithError:[NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorResourceUnavailable userInfo:nil]];
	}
}

- (void) stopLoading
{
}

@end
