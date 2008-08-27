#import "LibraryComProtocol.h"
#import "JSONKit/JSONKit.h"

@interface LibraryComProtocol (Private)
- (void) _dataCameIn:(NSNotification*)notification;
@end

@implementation LibraryComProtocol

@synthesize fileHandleForReading;
@synthesize fileHandleForWriting;
@synthesize delegate;

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
    if ([delegate respondsToSelector:@selector(engineMessageWasReceived:)]) {
        _canCallEngineMethodWasReceived = YES;
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

///
/// Send a message to the engine across the output side of things
///
- (void) sendMessage:(NSDictionary*)dict 
{
    // JSON data from Jason
    NSData* jsonData = [NSData dataWithObjectAsJSON:dict];
    NSString* jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    NSString* stringToSend = [NSString stringWithFormat:@"%d\n%@\n", [jsonString length] + 1, jsonString]; 
    

    NSLog(@"Sending: %@\n\n\n\n...\n\n\n\n", stringToSend);
    
    NSData* dataToSend = [stringToSend dataUsingEncoding:NSUTF8StringEncoding];
    [fileHandleForWriting writeData:dataToSend];
    
    [jsonString release];
    
    // Write the data to the output buffer
    //uint8_t byteBuffer[0x10];
    //NSData* data = [NSData dataWithBytes:buffer length:sprintf((char*)&byteBuffer, "%d\n", [jsonData length] + 1)];
    //[fileHandleForWriting writeData:data];
    //[fileHandleForWriting writeData:jsonData];
    
}

@end

@implementation LibraryComProtocol (Private)

///
/// Handle any incoming data off of the wire
///
- (void) _dataCameIn:(NSNotification*)notification
{
    // Get the data in
    NSDictionary *userinfo = [notification userInfo];
    NSData *data = [userinfo objectForKey:NSFileHandleNotificationDataItem]; 
    
    // Append it to the back of our buffer
    if (!data || [data length] == 0) {
        if (stdin) {
            NSLog(@"No data: stdin still alive");
        } else {
            NSLog(@"No data: stdin dead");
        }
        
        if (stdout) {
            NSLog(@"No data: stdout still alive");
        } else {
            NSLog(@"No data: stdout dead");
        }
    } else {
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
            
            NSLog(@"Received: %@\n\n\n\n...\n\n\n\n", messageText);
            
            NSDictionary* message = [NSDictionary dictionaryWithJSON:messageText];
            //NSLog(@"%@", messageText);
            
            NSData* oldCurrentBuffer = buffer;
            buffer = [[NSMutableData dataWithData:[buffer subdataWithRange:NSMakeRange((bp + bytesToRead) - bpBase, bpMax - (bp + bytesToRead))]] retain];
            [oldCurrentBuffer release];
            
            // Delegate it out
            if (_canCallEngineMethodWasReceived) {
                [delegate engineMessageWasReceived:message];
            }
        } while ([buffer length] > 0);
    }
    
    [fileHandleForReading readInBackgroundAndNotify];
}

@end

