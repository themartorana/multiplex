#import "Media.h"
#import "JSONKit/JSONKit.h"
#import "MediaSource.h"
#import <libkern/OSAtomic.h>

const CFStringRef kMDDiscDiscIdentFingerprint = CFSTR("com_discident_fingerprint");

extern void MDItemSetAttribute(MDItemRef, CFStringRef, CFTypeRef);
extern void MDItemRemoveAttribute(MDItemRef, CFStringRef);

@implementation Media

@synthesize fingerprint;
@synthesize mediaInfo;
@synthesize disc;
@synthesize url;
@synthesize mediaSource;

- (id) initWithMediaSource:(id<MediaSource>)_mediaSource mediaInfo:(void*)_mediaInfo;
{
    if (self = [super init]) {
        mediaSource = _mediaSource; // NOT RETAINED.
        mediaInfo = _mediaInfo; // NOT RETAINED.
    }
    return self;
}

- (void) dealloc
{
    [fingerprint release];
    [disc release];
    [url release];    
    [super dealloc];
}

- (void) reload
{
    NSAssert(mediaSource, @"No mediaSource?");
    [mediaSource reloadMedia:self];
}

- (NSString*) fingerprint
{
    NSAssert(mediaSource, @"No mediaSource?");
    return [mediaSource fingerprintForMedia:self];
}

- (NSString*) pathToFile
{
    NSAssert(mediaSource, @"No mediaSource?");
    return [mediaSource pathToFileForMedia:self];
}

- (NSMutableDictionary*) infoDictionary
{
    NSAssert(mediaSource, @"No mediaSource?");
    return [mediaSource infoDictionaryForMedia:self];
}

- (void) setInfoDictionary:(NSMutableDictionary*)infoDictionary
{
    NSAssert(mediaSource, @"No mediaSource?");
    [mediaSource setInfoDictionary:infoDictionary forMedia:self];
}

- (void) setFrontCover:(NSImage*)coverArt
{
    [mediaSource setFrontCover:coverArt forMedia:self];
}

@end
