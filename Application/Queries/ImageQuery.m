#import "ImageQuery.h"
#import "Query+Private.h"

#pragma mark -
@implementation ImageQuery

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

- (void) _fireDidReceiveData:(NSData*)data ofType:(NSString*)type 
{
    if (![data length]) {
        [self _fireDidFailWithError:nil];
        return;
    }
    
    if ([delegate respondsToSelector:@selector(imageQuery:didReceiveData:ofType:userInfo:)]) {
        @try {
            [delegate imageQuery:self didReceiveData:data ofType:type userInfo:userInfo];
        } @catch (id _exception) {
            NSLog(@"%@: Exception during %s -- %@", NSStringFromClass([self class]), __PRETTY_FUNCTION__, _exception);
        }
    }
    
    if ([delegate respondsToSelector:@selector(imageQuery:didReceiveImage:userInfo:)]) {
        NSImage* image = nil;
        @try {
            image = [[NSImage alloc] initWithData:data];
            [delegate imageQuery:self didReceiveImage:image userInfo:userInfo];
        } @catch (id _exception) {
            NSLog(@"%@: Exception during %s -- %@", NSStringFromClass([self class]), __PRETTY_FUNCTION__, _exception);
        }
        [image release];
    }
    
    if ([delegate respondsToSelector:@selector(imageQuery:didReceiveImageSource:userInfo:)]) {
        CGImageSourceRef imageSource = CGImageSourceCreateWithData((CFDataRef)data, nil);
        if (imageSource) {
            @try {
                [delegate imageQuery:self didReceiveImageSource:imageSource userInfo:userInfo];
            } @catch (id _exception) {
                NSLog(@"%@: Exception during %s -- %@", NSStringFromClass([self class]), __PRETTY_FUNCTION__, _exception);
            }
            CFRelease(imageSource);
        }
    }
}

- (void) _fireDidFailWithError:(NSError*)error
{
    if ([delegate respondsToSelector:@selector(imageQuery:didFailWithError:userInfo:)]) {
        @try {
            [delegate imageQuery:self didFailWithError:error userInfo:userInfo];
        } @catch (id _exception) {
            NSLog(@"%@: Exception during %s -- %@", NSStringFromClass([self class]), __PRETTY_FUNCTION__, _exception);
        }
    }
}

@end
