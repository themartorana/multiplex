#import "JSONQuery.h"
#import "Query+Private.h"
#import <JSONKit/JSONKit.h>

@implementation JSONQuery

+ (id) JSONQueryWithURL:(NSURL*)url
{
    return [[[JSONQuery alloc] initWithURL:url] autorelease];
}

+ (id) JSONQueryWithURL:(NSURL*)url delegate:(id)delegate userInfo:(id)userInfo startImmediately:(BOOL)startImmediately
{
    NSAssert(delegate, @"The delegate must not be nil.");
    JSONQuery* query = [JSONQuery JSONQueryWithURL:url];
    query.delegate = delegate;
    query.userInfo = userInfo;
    if (startImmediately) {
        [query start];
    }
    return query;
}

- (void) _fireDidReceiveData:(NSData*)data ofType:(NSString*)type 
{
    id object = nil;
    if (![data length]) {
        [self _fireDidFailWithError:nil];
        return;
    } else @try {
        object = [NSObject objectWithJSON:[[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease]];
    } @catch (id exception) {
        [self _fireDidFailWithError:nil];
        return;
    }
    
    if ([delegate respondsToSelector:@selector(JSONQuery:didReceiveObject:userInfo:)]) {
        @try {
            [delegate JSONQuery:self didReceiveObject:object userInfo:userInfo];
        } @catch (id _exception) {
            NSLog(@"%@: Exception during %s -- %@", NSStringFromClass([self class]), __PRETTY_FUNCTION__, _exception);
        }
    }
}

- (void) _fireDidFailWithError:(NSError*)error
{
    if ([delegate respondsToSelector:@selector(JSONQuery:didFailWithError:userInfo:)]) {
        @try {
            [delegate JSONQuery:self didFailWithError:error userInfo:userInfo];
        } @catch (id _exception) {
            NSLog(@"%@: Exception during %s -- %@", NSStringFromClass([self class]), __PRETTY_FUNCTION__, _exception);
        }
    }
}

@end
