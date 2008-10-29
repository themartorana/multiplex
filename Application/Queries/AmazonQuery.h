#import <Cocoa/Cocoa.h>

@interface AmazonQuery : NSObject {
    NSMutableData* receivedData;
    NSURLRequest* request;
    NSURLConnection* connection;
    /**/
    NSString* accessKey;
    NSString* ean;
    id delegate;
    id userInfo;
}

@property (readonly) NSString* ean;
@property (assign) id delegate;
@property (retain) id userInfo;

+ (id) amazonQueryWithAccessKey:(NSString*)accessKey ean:(NSString*)ean;
+ (id) amazonQueryWithAccessKey:(NSString*)accessKey ean:(NSString*)ean delegate:(id)delegate userInfo:(id)userInfo startImmediately:(BOOL)startImmediately;

- (id) initWithAccessKey:(NSString*)accessKey ean:(NSString*)ean;

- (void) start;
- (void) cancel;

@end

@interface NSObject (AmazonQueryDelegate)

- (void) amazonQuery:(AmazonQuery*)query didReceiveResponse:(NSDictionary*)response userInfo:(id)userInfo;
- (void) amazonQuery:(AmazonQuery*)query didFailWithError:(NSError*)error userInfo:(id)userInfo;

@end