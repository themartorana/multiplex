#import <Cocoa/Cocoa.h>
#import <CoreData/CoreData.h>
#import "MediaFile.h"
#import "MediaFileSource.h"
#import "HTTPServer.h"

@interface Engine : NSApplication <MediaFileSourceDelegate> {
    NSManagedObjectModel* managedObjectModel;
    NSPersistentStoreCoordinator* persistentStoreCoordinator;
    NSManagedObjectContext* managedObjectContext;
    NSEntityDescription* discEntity;
    /**/
    NSMutableDictionary* mediaByURL;
    NSMutableDictionary* infoDictionariesByFingerprint;
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
