#import "MessageProtocol.h"
#import "JSONKit/JSONKit.h"

@interface MessageProtocol (Private)
- (void) _fireDidReceiveMessage:(NSDictionary*)message;
- (void) _fireDidClose;
- (void) _dataCameIn:(NSNotification*)notification;
@end

@implementation MessageProtocol

@synthesize fileHandleForReading;
@synthesize fileHandleForWriting;
@synthesize delegate;
@synthesize userInfo;

+ (id) protocolWithDelegate:(id)delegate fileHandleForReading:(NSFileHandle*)fileHandleForReading fileHandleForWriting:(NSFileHandle*)fileHandleForWriting;
{
    NSAssert(delegate, @"Delegate must not be nil.");
    NSAssert(fileHandleForReading, @"fileHandleForReading must not be nil.");
    NSAssert(fileHandleForWriting, @"fileHandleForWriting must not be nil.");
    MessageProtocol* protocol = [[[MessageProtocol alloc] init] autorelease];
    protocol.delegate = delegate;
    protocol.fileHandleForReading = fileHandleForReading;
    protocol.fileHandleForWriting = fileHandleForWriting;
    return protocol;
}

- (id) init 
{
    if (self = [super init]) {
        buffer = [[NSMutableData alloc] initWithCapacity:0x1000];
    }
    return self;
}

- (void) dealloc
{
    NSAssert(buffer == nil, @"close not called before dealloc!");
    [super dealloc];
}

- (void) close
{
    if (buffer) {
        [self setFileHandleForReading:nil];
        [self setFileHandleForWriting:nil];
        [buffer release];
        buffer = nil;
        [self _fireDidClose];
    }
}

- (void) setDelegate:(id)_delegate
{
    NSAssert(buffer, @"This protocol has been closed.");
    delegate = _delegate;
    canCallDidReceiveMessage = [delegate respondsToSelector:@selector(protocol:didReceiveMessage:)];
    canCallDidClose = [delegate respondsToSelector:@selector(protocolDidClose:)];
}

- (void) setFileHandleForWriting:(NSFileHandle*)_fileHandleForWriting
{
    NSAssert(buffer, @"This protocol has been closed.");
    if (fileHandleForWriting != _fileHandleForWriting) {
        [fileHandleForWriting release];
        fileHandleForWriting = [_fileHandleForWriting retain];
    }
}

- (void) setFileHandleForReading:(NSFileHandle*)_fileHandleForReading 
{
    NSAssert(buffer, @"This protocol has been closed.");
    if (fileHandleForReading != _fileHandleForReading) {
        NSNotificationCenter* notificationCenter = [NSNotificationCenter defaultCenter];

        [notificationCenter removeObserver:self name:NSFileHandleReadCompletionNotification object:fileHandleForReading];
        [fileHandleForReading autorelease];

        if (_fileHandleForReading) {
            // Set up listener
            fileHandleForReading = [_fileHandleForReading retain];
            [notificationCenter addObserver:self selector:@selector(_dataCameIn:) name:NSFileHandleReadCompletionNotification object:fileHandleForReading]; 

            // Set up the standard read notification watcher
            [fileHandleForReading readInBackgroundAndNotify];
        }
    }
}

- (void) sendMessage:(NSDictionary*)message 
{
    NSAssert(buffer, @"This protocol has been closed.");
    @synchronized (self) {
        NSData* jsonData = [NSData dataWithObjectAsJSON:message];
        [fileHandleForWriting writeData:[[NSString stringWithFormat:@"%d\n", [jsonData length]] dataUsingEncoding:NSUTF8StringEncoding]];
        [fileHandleForWriting writeData:jsonData];
    }
}

@end

@implementation MessageProtocol (Private)

- (void) _fireDidReceiveMessage:(NSDictionary*)message  
{
    @try {
        if (canCallDidReceiveMessage) {
            [delegate protocol:self didReceiveMessage:message];
        }
    } @catch (id exception) {
        NSLog(@"MessageProtocol: Exception during protocol:didReceiveMessage: -- %@", exception);
    }
}

- (void) _fireDidClose
{
    @try {
        if (canCallDidClose) {
            [delegate protocolDidClose:self];
        }
    } @catch (id exception) {
        NSLog(@"MessageProtocol: Exception during protocolDidClose: -- %@", exception);
    }
}

///
/// Handle any incoming data off of the wire
///
- (void) _dataCameIn:(NSNotification*)notification
{
    NSData *data = [[notification userInfo] objectForKey:NSFileHandleNotificationDataItem]; 
    if (data && [data length]) {
        [buffer appendData:data];
        do {
            const uint8_t* bpBase = [buffer bytes];
            const uint8_t* bp = bpBase;
            const uint8_t* bpMax = bpBase + [buffer length];

            int bytesToRead = 0;
            for (; bp < bpMax && *bp != '\r' && *bp != '\n'; bp++) {
                int digit = *bp - '0';
                if (0 > digit || digit > 9) {
                    [self close];
                    return;
                }
                bytesToRead = (bytesToRead * 10) + digit;
            }
            if (*bp == '\r') {
                bp++;
            }
            if (*bp++ != '\n' || bytesToRead > (bpMax - bp)) {
                break;
            }

            NSString* messageText = [[NSString alloc] initWithData:[buffer subdataWithRange:NSMakeRange(bp - bpBase, bytesToRead)] encoding:NSUTF8StringEncoding];
            [self _fireDidReceiveMessage:[NSDictionary dictionaryWithJSON:messageText]];
            
            NSData* oldCurrentBuffer = buffer;
            buffer = [[NSMutableData dataWithData:[buffer subdataWithRange:NSMakeRange((bp + bytesToRead) - bpBase, bpMax - (bp + bytesToRead))]] retain];
            [oldCurrentBuffer release];
        } while ([buffer length] > 0);

        [fileHandleForReading readInBackgroundAndNotify];
    } else {
        [self close];
    }
}

@end

