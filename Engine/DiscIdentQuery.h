#import <Cocoa/Cocoa.h>
#import "Media.h"

@interface DiscIdentQuery : NSObject {
    NSMutableData* receivedData;
    NSURLRequest* request;
    NSURLConnection* connection;
    /**/
    id delegate;
}

@property (assign) id delegate;

+ (id) queryWithFingerprint:(NSString*)fingerprint;

- (id) initWithFingerprint:(NSString*)fingerprint;

- (void) start;
- (void) cancel;


@end

@interface NSObject (DiscIdentQueryDelegate)

- (void) discIdentQuery:(DiscIdentQuery*)query didReceiveResponse:(NSDictionary*)response;
- (void) discIdentQuery:(DiscIdentQuery*)query didFailWithError:(NSError*)error;

@end