#import <Cocoa/Cocoa.h>
#import "Query.h"

@interface ImageQuery : Query {
}

+ (id) imageQueryWithURL:(NSURL*)url;
+ (id) imageQueryWithURL:(NSURL*)url delegate:(id)delegate userInfo:(id)userInfo startImmediately:(BOOL)startImmediately;

@end

@interface NSObject (ImageQueryDelegate)

- (void) imageQuery:(ImageQuery*)query didReceiveData:(NSData*)data ofType:(NSString*)type userInfo:(id)userInfo;
- (void) imageQuery:(ImageQuery*)query didReceiveImage:(NSImage*)image userInfo:(id)userInfo;
- (void) imageQuery:(ImageQuery*)query didReceiveImageSource:(CGImageSourceRef)imageSource userInfo:(id)userInfo;
- (void) imageQuery:(ImageQuery*)query didFailWithError:(NSError*)error userInfo:(id)userInfo;

@end