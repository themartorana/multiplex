#import <Cocoa/Cocoa.h>

@interface AmazonQuery : NSObject {
    NSMutableData* receivedData;
    NSURLRequest* request;
    NSURLConnection* connection;
    /**/
    NSString* accessKey;
    NSString* ean;
    id delegate;
    void* userInfo;
}

@property (readonly) NSString* ean;
@property (assign) id delegate;
@property (assign) void* userInfo;

+ (id) queryWithAccessKey:(NSString*)accessKey ean:(NSString*)ean;
+ (id) queryWithAccessKey:(NSString*)accessKey ean:(NSString*)ean delegate:(id)delegate userInfo:(void*)userInfo startImmediately:(BOOL)startImmediately;

- (id) initWithAccessKey:(NSString*)accessKey ean:(NSString*)ean;

- (void) start;
- (void) cancel;

@end

@interface NSObject (AmazonQueryDelegate)

- (void) amazonQuery:(AmazonQuery*)query didReceiveResponse:(NSDictionary*)response userInfo:(void*)userInfo;
- (void) amazonQuery:(AmazonQuery*)query didFailWithError:(NSError*)error userInfo:(void*)userInfo;

@end