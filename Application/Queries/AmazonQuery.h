#import <Cocoa/Cocoa.h>
#import "Query.h"

@interface AmazonQuery : Query {
    NSString* accessKey;
    NSString* ean;
}

@property (readonly) NSString* ean;

+ (id) amazonQueryWithAccessKey:(NSString*)accessKey ean:(NSString*)ean;
+ (id) amazonQueryWithAccessKey:(NSString*)accessKey ean:(NSString*)ean delegate:(id)delegate userInfo:(id)userInfo startImmediately:(BOOL)startImmediately;

- (id) initWithAccessKey:(NSString*)accessKey ean:(NSString*)ean;

@end

@interface NSObject (AmazonQueryDelegate)

- (void) amazonQuery:(AmazonQuery*)query didReceiveResponse:(NSDictionary*)response userInfo:(id)userInfo;
- (void) amazonQuery:(AmazonQuery*)query didFailWithError:(NSError*)error userInfo:(id)userInfo;

@end