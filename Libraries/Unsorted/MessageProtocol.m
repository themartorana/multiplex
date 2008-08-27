#import "MessageProtocol.h"
#import "JSONKit/JSONKit.h"

@interface MessageProtocol (Private)
- (void) _fireDidReceiveMessage:(NSDictionary*)message;
- (void) _dataCameIn:(NSNotification*)notification;
@end

@implementation MessageProtocol

@synthesize fileHandleForReading;
@synthesize fileHandleForWriting;
@synthesize delegate;

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
    [buffer dealloc];
    [self setFileHandleForReading:nil];
    [self setFileHandleForWriting:nil];
    [super dealloc];
}

- (void) setDelegate:(id)_delegate
{
    delegate = _delegate;
    if ([delegate respondsToSelector:@selector(protocol:didReceiveMessage:)]) {
        canCallDidReceiveMessage = YES;
    }
}

- (void) setFileHandleForReading:(NSFileHandle*)_fileHandleForReading 
{
    if (fileHandleForReading != _fileHandleForReading) {
        NSNotificationCenter* notificationCenter = [NSNotificationCenter defaultCenter];

        [notificationCenter removeObserver:self name:NSFileHandleReadCompletionNotification object:fileHandleForReading];
        [fileHandleForReading autorelease];

        if (_fileHandleForReading) {
            // Set up listener
            // Set up the standard read notification watcher
            fileHandleForReading = [_fileHandleForReading retain];
            [notificationCenter addObserver:self selector:@selector(_dataCameIn:) name:NSFileHandleReadCompletionNotification object:fileHandleForReading]; 

            [fileHandleForReading readInBackgroundAndNotify];
        }
    }
}

- (void) sendMessage:(NSDictionary*)message 
{
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

///
/// Handle any incoming data off of the wire
///
- (void) _dataCameIn:(NSNotification*)notification
{
    NSDictionary *userinfo = [notification userInfo];
    NSData *data = [userinfo objectForKey:NSFileHandleNotificationDataItem]; 

    if (data && [data length]) {
        [buffer appendData:data];
        do {
            int bytesToRead = 0;
            const uint8_t* bpBase = [buffer bytes];
            const uint8_t* bp = bpBase;
            const uint8_t* bpMax = bpBase + [buffer length];
            for (; bp < bpMax && *bp != '\n'; bp++) {
                int digit = *bp - '0';
                NSAssert1(0 <= digit && digit <= 9, @"Something went horribly wrong! Digit is %d", digit);
                bytesToRead = (bytesToRead * 10) + digit;
            }
            int end = bpMax - bp;
            if (*bp++ != '\n' || bytesToRead > end) {
                break;
            }
            
            NSString* messageText = [[NSString alloc] initWithData:[buffer subdataWithRange:NSMakeRange(bp - bpBase, bytesToRead)] encoding:NSUTF8StringEncoding];
            [self _fireDidReceiveMessage:[NSDictionary dictionaryWithJSON:messageText]];
#ifdef DEBUG            
            NSLog(@"Received: %@\n\n\n\n...\n\n\n\n", messageText);
#endif

            NSData* oldCurrentBuffer = buffer;
            buffer = [[NSMutableData dataWithData:[buffer subdataWithRange:NSMakeRange((bp + bytesToRead) - bpBase, bpMax - (bp + bytesToRead))]] retain];
            [oldCurrentBuffer release];
        } while ([buffer length] > 0);
    }
    
    [fileHandleForReading readInBackgroundAndNotify];
}

@end

