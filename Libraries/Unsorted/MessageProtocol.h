#import <Cocoa/Cocoa.h>

@interface MessageProtocol : NSObject 
{
    NSFileHandle* fileHandleForReading;
    NSFileHandle* fileHandleForWriting;
    id delegate;
    void* userInfo;
    /**/
    NSMutableData* buffer;
    BOOL canCallDidReceiveMessage;
    BOOL canCallDidClose;
}

@property (retain) NSFileHandle* fileHandleForReading;
@property (retain) NSFileHandle* fileHandleForWriting;
@property (assign) id delegate;
@property (assign) void* userInfo;

+ (id) protocolWithDelegate:(id)delegate fileHandleForReading:(NSFileHandle*)fileHandleForReading fileHandleForWriting:(NSFileHandle*)fileHandleForWriting;

- (void) sendMessage:(NSDictionary*)message;
- (void) close;

@end

@interface NSObject (LibraryComProtocolDelegate)

- (void) protocol:(MessageProtocol*)protocol didReceiveMessage:(NSDictionary*)message;
- (void) protocolDidClose:(MessageProtocol*)protocol;

@end