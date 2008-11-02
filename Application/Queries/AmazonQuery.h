#import <Cocoa/Cocoa.h>
#import "Query.h"

typedef enum _AmazonQueryType
{
    AmazonQueryTypeEAN = 1,
    AmazonQueryTypeTitle = 2
} AmazonQueryType;

@interface AmazonQuery : Query {
    AmazonQueryType queryType;
    
    NSString* accessKey;
    NSString* ean;
    NSString* titleKeywords;
}

@property (readonly) NSString* ean;
@property (readonly) AmazonQueryType queryType;

+ (id) amazonQueryWithAccessKey:(NSString*)accessKey ean:(NSString*)ean;
+ (id) amazonQueryWithAccessKey:(NSString*)accessKey ean:(NSString*)ean delegate:(id)delegate userInfo:(id)userInfo startImmediately:(BOOL)startImmediately;
- (id) initWithAccessKey:(NSString*)accessKey ean:(NSString*)ean;

+ (id) amazonQueryWithAccessKey:(NSString*)accessKey titleKeywords:(NSString*)titleKeywords;
+ (id) amazonQueryWithAccessKey:(NSString*)accessKey titleKeywords:(NSString*)titleKeywords delegate:(id)delegate userInfo:(id)userInfo startImmediately:(BOOL)startImmediately;
- (id) initWithAccessKey:(NSString*)accessKey titleKeywords:(NSString*)titleKeywords;

@end

@interface NSObject (AmazonQueryDelegate)

- (void) amazonQuery:(AmazonQuery*)query didReceiveResponse:(NSArray*)response userInfo:(id)userInfo;
- (void) amazonQuery:(AmazonQuery*)query didFailWithError:(NSError*)error userInfo:(id)userInfo;

@end