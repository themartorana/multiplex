#import <Cocoa/Cocoa.h>

@interface HTTPConnection : NSObject {
    BOOL replySent;
    NSFileHandle *fileHandle;
    id delegate;
    NSString *address;
    CFHTTPMessageRef httpMessage;
    BOOL isMessageComplete;
}

- (id) initWithFileHandle:(NSFileHandle*)_fileHandle address:(NSString*)address delegate:(id)_delegate;

@property (readonly) NSFileHandle* fileHandle;
@property (readonly) NSString* address;

- (void)replyWithStatusCode:(int)code headers:(NSDictionary*)headers body:(NSData*)body;
- (void)replyWithData:(NSData*)data MIMEType:(NSString*)type;
- (void)replyWithStatusCode:(int)code message:(NSString*)message;

@end

@interface HTTPServer : NSObject {
    id delegate;
    NSSocketPort* socketPort;
    NSFileHandle* fileHandle;
}

- (id) initWithSocketPort:(NSSocketPort*)socketPort delegate:(id)delegate;

@end


@interface NSObject (HTTPServerDelegate)
- (void) processURL:(NSURL*)url connection:(HTTPConnection*)connection;
@end
