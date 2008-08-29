#import <CoreFoundation/CoreFoundation.h>
#import <CoreServices/CoreServices.h> 
#import <Cocoa/Cocoa.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <openssl/md5.h>
#include <sys/syslimits.h>
#include "NSDate+Mothership.h"
#include "JSONKit/JSONKit.h"

const static NSString* kMDItemDiscIdentFingerprint = @"com_discident_fingerprint";

NSString* computeDiscIdentFingerprintForPath(NSString* pathToFile) 
{
	/*	Do some quick checks.
	 */
    NSFileManager* fileManager = [NSFileManager defaultManager];
    BOOL isDirectory = FALSE;
    if (![fileManager fileExistsAtPath:pathToFile isDirectory:&isDirectory] || !isDirectory) {
        return nil;
    }
	NSString* videoPath = [pathToFile stringByAppendingPathComponent:@"VIDEO_TS"];
    if (![fileManager fileExistsAtPath:videoPath isDirectory:&isDirectory] || !isDirectory) {
        return nil;
    }

	/*  Build up the string that we hash to produce the fingerprint.
	 */
	NSMutableData* data = [NSMutableData data];
    for (NSString* path in [[fileManager subpathsAtPath:videoPath] sortedArrayUsingSelector:@selector(compare:)]) {
        if ([path length] > 0 && [path characterAtIndex:0] != '.') {
            struct stat sb;
            if (0 != stat([[videoPath stringByAppendingPathComponent:path] fileSystemRepresentation], &sb)) {
                return nil;
            }
            char buffer[PATH_MAX];
            int length = sprintf(buffer, ":%s", [[@"/VIDEO_TS" stringByAppendingPathComponent:path] UTF8String]);
            if (0 == (sb.st_mode & S_IFDIR)) {
                length += sprintf(buffer + length, ":%lld", sb.st_size);
            }
            [data appendBytes:buffer length:length];
        }
    }
	
    /*  Generate the fingerprint.
     */
    unsigned char fingerprint[MD5_DIGEST_LENGTH];
    MD5_CTX ctx;
    MD5_Init(&ctx);
    MD5_Update(&ctx, [data bytes], [data length]);
    MD5_Final(fingerprint, &ctx);

    /*  Put the final twist on it for for human-readability.
     */
    char readableFingerprint[(MD5_DIGEST_LENGTH * 2) + 4 + 1];
    sprintf(
        readableFingerprint,
        "%02X%02X%02X%02X-"\
        "%02X%02X-"\
        "%02X%02X-"\
        "%02X%02X-"\
        "%02X%02X%02X%02X%02X%02X",
        fingerprint[0x00], fingerprint[0x01], fingerprint[0x02], fingerprint[0x03],
        fingerprint[0x04], fingerprint[0x05], 
        fingerprint[0x06], fingerprint[0x07],
        fingerprint[0x08], fingerprint[0x09], 
        fingerprint[0x0A], fingerprint[0x0B], fingerprint[0x0C], fingerprint[0x0D], fingerprint[0x0E], fingerprint[0x0F]
    );
	return [NSString stringWithCString:readableFingerprint];
}

BOOL GetMetadataForFile(void* thisInterface, NSMutableDictionary* attributes, NSString* contentTypeUTI, NSString* pathToFile)
{
    @try {
        NSString* infoFile = [pathToFile stringByAppendingPathComponent:@"Info.json"];
        NSMutableDictionary* info = nil;
        NSString* fingerprint = nil;

        @try {
            info = [NSMutableDictionary dictionaryWithJSON:[NSString stringWithContentsOfFile:infoFile]];
            fingerprint = [info objectForKey:@"fingerprint"];
        } @catch (id exception) {
            /* ignored */
        }

        if (!fingerprint) {
            fingerprint = computeDiscIdentFingerprintForPath(pathToFile);
            if (!info) {
                info = [NSMutableDictionary dictionaryWithObject:fingerprint forKey:@"fingerprint"];
            } else {
                [info setObject:fingerprint forKey:fingerprint]; 
            }
            [[NSData dataWithObjectAsJSON:[NSDictionary dictionaryWithDictionary:info]] writeToFile:infoFile atomically:YES];                    
        }

        NSDictionary* movie = [info objectForKey:@"movie"];
        if (movie) {
            NSString* title = [movie objectForKey:@"title"];
            if (title) {
                [attributes setObject:title forKey:(NSString*)kMDItemDisplayName];
                [attributes setObject:title forKey:(NSString*)kMDItemTitle];
            }
            
            NSString* releaseDateString = [movie objectForKey:@"releasedate"];
            if (releaseDateString) {
                NSDate* releaseDate = [NSDate dateFromShortDateString:releaseDateString];
                if (releaseDate) {
                    [attributes setObject:releaseDate forKey:(NSString*)kMDItemContentCreationDate];
                }
            }
            
            NSArray* publishers = [movie objectForKey:@"publishers"];
            if (publishers) {
                [attributes setObject:publishers forKey:(NSString*)kMDItemPublishers];
            }
            
            NSArray* actors = [movie objectForKey:@"actors"];
            if (actors) {
                [attributes setObject:actors forKey:(NSString*)kMDItemContributors];
            }
            
            NSNumber* rating = [movie objectForKey:@"rating"];
            if (rating) {
                [attributes setObject:rating forKey:(NSString*)kMDItemAudiences];
            }
            
            if ([movie objectForKey:@"description"]) {
                [attributes setObject:[movie objectForKey:@"description"] forKey:(NSString*)kMDItemDescription];
            }
        }
            
        NSArray* applications = [info objectForKey:@"applications"];
        if (applications) {
            [attributes setObject:applications forKey:(NSString*)kMDItemEncodingApplications];  
        }

        [attributes setObject:@"public.dvdmedia" forKey:(NSString*)kMDItemContentType];
        [attributes setObject:fingerprint forKey:@"com_discident_fingerprint"];
    } @catch (id exception) {
        return FALSE;
    }
    return TRUE;
}
