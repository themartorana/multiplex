#import <Cocoa/Cocoa.h>

@interface CoverArtQuery : NSObject {
    NSMutableData* receivedData;
    NSURLRequest* request;
    NSURLConnection* connection;
    /**/
    NSString* accessKey;
    NSURL* URL;
    id delegate;
    void* userInfo;
}

@property (readonly) NSURL* URL;
@property (assign) id delegate;
@property (assign) void* userInfo;

+ (id) queryWithURL:(NSURL*)url;
+ (id) queryWithURL:(NSURL*)url delegate:(id)delegate userInfo:(void*)userInfo startImmediately:(BOOL)startImmediately;

- (id) initWithURL:(NSURL*)url;

- (void) start;
- (void) cancel;

@end

@interface NSObject (CoverArtQueryDelegate)

- (void) coverArtQuery:(CoverArtQuery*)query didReceiveResponse:(NSImage*)image userInfo:(void*)userInfo;
- (void) coverArtQuery:(CoverArtQuery*)query didFailWithError:(NSError*)error userInfo:(void*)userInfo;

@end