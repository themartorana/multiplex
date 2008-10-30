#import "MediaFile.h"
#import "JSONKit/JSONKit.h"
#import "MediaFileSource.h"
#import <libkern/OSAtomic.h>

const CFStringRef kMDDiscDiscIdentFingerprint = CFSTR("com_discident_fingerprint");

extern void MDItemSetAttribute(MDItemRef, CFStringRef, CFTypeRef);
extern void MDItemRemoveAttribute(MDItemRef, CFStringRef);

@implementation MediaFile

@synthesize fingerprint;
@synthesize mediaInfo;
@synthesize tag;
@synthesize mediaFileSource;
@synthesize frontCover;

- (id) initWithMediaSource:(id<MediaFileSource>)_mediaFileSource mediaInfo:(void*)_mediaInfo;
{
    if (self = [super init]) {
        mediaFileSource = _mediaFileSource; // NOT RETAINED.
        mediaInfo = _mediaInfo; // NOT RETAINED.
    }
    return self;
}

- (void) dealloc
{
    [fingerprint release];
    [disc release];
    [tag release];    
    [super dealloc];
}

- (void) reload
{
    NSAssert(mediaFileSource, @"No mediaSource?");
    [mediaFileSource reloadMedia:self];
}

- (NSString*) fingerprint
{
    NSAssert(mediaFileSource, @"No mediaSource?");
    return [mediaFileSource fingerprintForMedia:self];
}

- (NSString*) pathToFile
{
    NSAssert(mediaFileSource, @"No mediaSource?");
    return [mediaFileSource pathToFileForMedia:self];
}

- (NSMutableDictionary*) infoDictionary
{
    NSAssert(mediaFileSource, @"No mediaSource?");
    return [mediaFileSource infoDictionaryForMedia:self];
}

- (void) setInfoDictionary:(NSMutableDictionary*)infoDictionary
{
    NSAssert(mediaFileSource, @"No mediaSource?");
    [mediaFileSource setInfoDictionary:infoDictionary forMedia:self];
}

- (NSData*) frontCover
{
    return [mediaFileSource frontCoverForMedia:self];
}

- (void) setFrontCover:(NSData*)frontCover
{
    [mediaFileSource setFrontCover:frontCover forMedia:self];
}

@end
