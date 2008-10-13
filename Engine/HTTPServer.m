#import "HTTPServer.h"
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>

@implementation HTTPServer

- (id) initWithSocketPort:(NSSocketPort*)_socketPort delegate:(id)_delegate
{
    NSAssert(_socketPort != nil, @"socketPort is nil?");
    NSAssert(_delegate != nil, @"Please specify a delegate");
    NSAssert([_delegate respondsToSelector:@selector(processURL:connection:)], @"Delegate needs to implement 'processURL:connection:'");

    if (self = [super init]) {
        delegate = [_delegate retain];
        socketPort = [_socketPort retain];
        fileHandle = [[NSFileHandle alloc] initWithFileDescriptor:[socketPort socket] closeOnDealloc:YES];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_newConnection:) name:NSFileHandleConnectionAcceptedNotification object:fileHandle];
        [fileHandle acceptConnectionInBackgroundAndNotify];
    }
    return self;
}

- (void) dealloc
{
    NSAssert(!socketPort, @"shutdown hasn't been called.");
    [fileHandle release];
    [socketPort release];
    [delegate release];
    [super dealloc];
}

- (void) shutdown
{
    if (socketPort) {
        [socketPort release];
        socketPort = nil;
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
}

- (void) _newConnection:(NSNotification *)notification
{
    NSDictionary* userInfo = [notification userInfo];
    NSFileHandle* remoteFileHandle = [userInfo objectForKey:NSFileHandleNotificationFileHandleItem];
    NSNumber* errorNo = [userInfo objectForKey:@"NSFileHandleError"];
    if (errorNo) {
        NSLog(@"NSFileHandle Error: %@", errorNo);
        return;
    }

    [fileHandle acceptConnectionInBackgroundAndNotify];

    if (remoteFileHandle) {
        NSString* address = nil;
        CFSocketRef socket = CFSocketCreateWithNative(kCFAllocatorDefault, [remoteFileHandle fileDescriptor], kCFSocketNoCallBack, NULL, NULL);
        CFDataRef addrData = CFSocketCopyPeerAddress(socket);
        CFRelease(socket);
        if (addrData) {
            struct sockaddr_in* sock = (struct sockaddr_in*)CFDataGetBytePtr(addrData);
            address = [NSString stringWithCString:inet_ntoa(sock->sin_addr)];
            CFRelease(addrData);
        }

        [[HTTPConnection alloc] initWithFileHandle:remoteFileHandle address:address delegate:delegate];
    }
}

@end

@implementation HTTPConnection
@synthesize fileHandle;
@synthesize address;

- (id) initWithFileHandle:(NSFileHandle*)_fileHandle address:(NSString*)_address delegate:(id)_delegate
{
    if (self = [super init]) {
        fileHandle = [_fileHandle retain];
        delegate = [_delegate retain];
        address = [_address retain];
        isMessageComplete = YES;
        httpMessage = NULL;
        
        // Register for notification when data arrives
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self selector:@selector(_dataReceivedNotification:) name:NSFileHandleReadCompletionNotification object:fileHandle];
        [fileHandle readInBackgroundAndNotify];
    }
    return self;
}

- (void) dealloc
{
    if (httpMessage) {
        CFRelease(httpMessage);
    }
    [delegate release];
    [fileHandle release];
    [super dealloc];
}

- (void) _close
{
    @try {
        [fileHandle closeFile];
    } @finally {
        [fileHandle release];
        fileHandle = nil;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) _dataReceivedNotification:(NSNotification*)notification
{
    NSData* data = [[notification userInfo] objectForKey:NSFileHandleNotificationDataItem];
    
    if (![data length]) {
        // NSFileHandle's way of telling us that the client closed the connection
        [self _close];
    } else {
        [fileHandle readInBackgroundAndNotify];
        if (isMessageComplete) {
            httpMessage = CFHTTPMessageCreateEmpty(kCFAllocatorDefault, TRUE);
        }
        BOOL success = CFHTTPMessageAppendBytes(httpMessage, [data bytes], [data length]);
        if (success) {
            if (isMessageComplete = CFHTTPMessageIsHeaderComplete(httpMessage)) {
                CFURLRef url = CFHTTPMessageCopyRequestURL(httpMessage);
                @try {
                    [delegate processURL:(NSURL*)url connection:self];
                } @catch (id exception) {
                    if (!replySent) {
                        [self replyWithStatusCode:404 message:nil];
                    }
                }
                CFRelease(url);
                CFRelease(httpMessage);
                httpMessage = NULL;
                [self _close];
            }
        }
    }
}

- (void) replyWithStatusCode:(int)code headers:(NSDictionary*)headers body:(NSData*)body
{
    NSAssert(!replySent, @"Reply already sent!");
    replySent = YES;
    CFHTTPMessageRef msg = CFHTTPMessageCreateResponse(kCFAllocatorDefault, code, NULL, kCFHTTPVersion1_1);
    
    for (NSString* key in headers) {
        if (![key isKindOfClass:[NSString class]]) {
            key = [key description];
        }
        id value = [headers objectForKey:key];
        if (![value isKindOfClass:[NSString class]]) {
            value = [value description];
        }
        CFHTTPMessageSetHeaderFieldValue(msg, (CFStringRef)key, (CFStringRef)value);
    }
    
    if (body) {
        NSString* length = [NSString stringWithFormat:@"%d", [body length]];
        CFHTTPMessageSetHeaderFieldValue(msg, CFSTR("Content-Length"), (CFStringRef)length);
        CFHTTPMessageSetBody(msg, (CFDataRef)body);
    }
    
    CFDataRef msgData = CFHTTPMessageCopySerializedMessage(msg);
    @try {
        [fileHandle writeData:(NSData *)msgData];
    }
    @catch (NSException* exception) {
        NSLog(@"Error while sending response: %@", [exception  reason]);
    }
    
    CFRelease(msgData);
    CFRelease(msg);
}

- (void) replyWithData:(NSData*)data MIMEType:(NSString*)type
{
    NSAssert(!replySent, @"Reply already sent!");
    NSDictionary* headers = [NSDictionary dictionaryWithObject:type forKey:@"Content-Type"];
    [self replyWithStatusCode:200 headers:headers body:data];  // 200 = 'OK'
}

- (void) replyWithStatusCode:(int)code message:(NSString*)_message
{
    NSAssert(!replySent, @"Reply already sent!");
    NSData* body = nil;
    if ([_message length]) {
        body = [_message dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    }
    [self replyWithStatusCode:code headers:nil body:body];
}


@end
