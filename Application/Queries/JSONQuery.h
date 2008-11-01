#import <Cocoa/Cocoa.h>
#import "Query.h"

@interface JSONQuery : Query {
}

+ (id) JSONQueryWithURL:(NSURL*)url;
+ (id) JSONQueryWithURL:(NSURL*)url delegate:(id)delegate userInfo:(id)userInfo startImmediately:(BOOL)startImmediately;

@end

@interface NSObject (JSONQueryDelegate)

- (void) JSONQuery:(JSONQuery*)query didReceiveObject:(id)object userInfo:(id)userInfo;
- (void) JSONQuery:(JSONQuery*)query didFailWithError:(NSError*)error userInfo:(id)userInfo;

@end