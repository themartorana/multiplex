#import <Cocoa/Cocoa.h>

@class EngineController;

@interface LibraryComProtocol : NSObject 
{
    NSMutableData* buffer;
    
    NSFileHandle* fileHandleForReading;
    NSFileHandle* fileHandleForWriting;
    
    EngineController* _engineController;
    
    id delegate;
    
    BOOL _canCallEngineMethodWasReceived;
}

@property (retain) NSFileHandle* fileHandleForReading;
@property (retain) NSFileHandle* fileHandleForWriting;
@property (assign) id delegate;

- (void) sendMessage:(NSDictionary*)dict;

@end

@interface NSObject (LibraryComProtocolDelegate)

- (void) engineMessageWasReceived:(NSDictionary*)message;

@end