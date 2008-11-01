#import <Cocoa/Cocoa.h>

@interface Query : NSObject {
@private
    NSHTTPURLResponse* response;
    NSMutableData* receivedData;
    NSMutableURLRequest* request;
    NSURLConnection* connection;
    /**/
    NSURL* URL;
@protected
    id delegate;
    id userInfo;
}

@property (readonly) NSURL* URL;
@property (retain) id delegate;
@property (retain) id userInfo;

+ (id) queryWithURL:(NSURL*)url;
+ (id) queryWithURL:(NSURL*)url delegate:(id)delegate userInfo:(id)userInfo startImmediately:(BOOL)startImmediately;

- (id) initWithURL:(NSURL*)url;

- (void) start;
- (void) cancel;

@end

@interface NSObject (DataDelegate)

- (void) query:(Query*)query didFailWithError:(NSError*)error userInfo:(id)userInfo;
- (void) query:(Query*)query didReceiveData:(NSData*)data ofType:(NSString*)type userInfo:(id)userInfo;

@end