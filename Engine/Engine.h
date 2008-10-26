#import <Cocoa/Cocoa.h>
#import "MediaFile.h"
#import "MediaSource.h"
#import "HTTPServer.h"

@interface Engine : NSApplication <MediaSourceDelegate> {
    NSMutableDictionary* infoDictionariesByFingerprint;
    NSMutableDictionary* discsByFingerprint;
    NSMutableArray* protocols;
    NSString* machineId;
    NSString* machineName;
    NSMutableDictionary* txtData;
    int networkPort;
    NSNetService* netService;
    NSMutableArray* mediaSources;
    NSURL* baseImageURL;
    HTTPServer* imageServer;
}

@end
