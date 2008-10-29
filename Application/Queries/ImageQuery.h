#import <Cocoa/Cocoa.h>

@interface ImageQuery : NSObject {
    NSHTTPURLResponse* response;
    NSMutableData* receivedData;
    NSMutableURLRequest* request;
    NSURLConnection* connection;
    /**/
    NSURL* URL;
    id delegate;
    id userInfo;
}

@property (readonly) NSURL* URL;
@property (assign) id delegate;
@property (retain) id userInfo;

+ (id) imageQueryWithURL:(NSURL*)url;
+ (id) imageQueryWithURL:(NSURL*)url delegate:(id)delegate userInfo:(id)userInfo startImmediately:(BOOL)startImmediately;

- (id) initWithURL:(NSURL*)url;

- (void) start;
- (void) cancel;

@end

@interface NSObject (CoverArtQueryDelegate)

- (void) imageQuery:(ImageQuery*)query didReceiveData:(NSData*)data ofType:(NSString*)type userInfo:(id)userInfo;
- (void) imageQuery:(ImageQuery*)query didReceiveImage:(NSImage*)image userInfo:(id)userInfo;
- (void) imageQuery:(ImageQuery*)query didReceiveImageSource:(CGImageSourceRef)imageSource userInfo:(id)userInfo;
- (void) imageQuery:(ImageQuery*)query didFailWithError:(NSError*)error userInfo:(id)userInfo;

@end