#import <CoreFoundation/CoreFoundation.h>
#import <CoreServices/CoreServices.h> 
#import <Cocoa/Cocoa.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <openssl/md5.h>
#include <sys/syslimits.h>
#include "NSDate+Mothership.h"
#include "JSONKit/JSONKit.h"

const CFStringRef kMDItemDiscIdentFingerprint	= (CFStringRef)@"com_discident_fingerprint";

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

// Check to see if an Info.json file exists inside of the .dvdmedia package.  If it does,
// translate those key/value pairs 
void GetSpotlightInfoFromJSON(NSString* pathToFile, NSMutableDictionary* attributes)
{
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    
    NSFileManager* fm = [NSFileManager defaultManager];
    NSMutableDictionary* md;
    
    if ([fm fileExistsAtPath:[pathToFile stringByAppendingPathComponent:@"_Info.json"]]) {
        // Later, import the JSON data into an NSDictionary
        NSString* path = [pathToFile stringByAppendingPathComponent:@"_Info.json"];
        NSString* jsonText = [NSString stringWithContentsOfFile:path];
        NSDictionary *fromJSON =[NSDictionary dictionaryWithJSON:jsonText];
        md = [[NSMutableDictionary alloc] initWithDictionary:fromJSON];
        
        if ([md objectForKey:(NSString*)kMDItemDiscIdentFingerprint])
            [attributes setObject:[md objectForKey:(NSString*)kMDItemDiscIdentFingerprint] forKey:(NSString*)kMDItemDiscIdentFingerprint];
        
        // Make sure our dictionary is cool
        /*if (![md objectForKey:@"movie"]) {
            NSLog(@"md dictionary is nil");
        }
        else if (![[[md objectForKey:@"movie"] class]isSubclassOfClass:[NSDictionary class]]) {
            NSLog([@"md is not of type dictionary, is of type " stringByAppendingString:[[[md objectForKey:@"movie"] class] description]]);
            return;            
        }*/
        
        if (![md objectForKey:@"movie"]) {
        
            // Get the movie dict and remove values from it.
            NSDictionary *moviedict = (NSDictionary*)[md objectForKey:@"movie"];
            
            // Movie title
            if ([moviedict objectForKey:@"title"]) {
                [attributes setObject:[moviedict objectForKey:@"title"] forKey:(NSString*)kMDItemDisplayName];
                [attributes setObject:[moviedict objectForKey:@"title"] forKey:(NSString*)kMDItemTitle];
            }
            
            // Release date
            if ([moviedict objectForKey:@"releasedate"]){
                NSString* releasedatestring = (NSString*)[moviedict objectForKey:@"releasedate"];
                NSDate* releasedate = [NSDate dateFromShortDateString:releasedatestring];
                [attributes setObject:releasedate forKey:(NSString*)kMDItemContentCreationDate];
            }
            
            // Publishers
            if ([moviedict objectForKey:@"publishers"])
                [attributes setObject:[moviedict objectForKey:@"publishers"] forKey:(NSString*)kMDItemPublishers];
            
            // Actors
            if ([moviedict objectForKey:@"actors"])
                [attributes setObject:[moviedict objectForKey:@"actors"] forKey:(NSString*)kMDItemContributors];
            
            // Rating(s)
            if ([moviedict objectForKey:@"rating"])
                [attributes setObject:[moviedict objectForKey:@"rating"] forKey:(NSString*)kMDItemAudiences];
            
            // Run time of movie
            if ([moviedict objectForKey:@"runtime"]) {
                // Put in code to calculate this.
                // Waiting until I see the different formats that might come back from our
                // metadata sources
            }
            
            // Rating(s)
            if ([moviedict objectForKey:@"description"])
                [attributes setObject:[moviedict objectForKey:@"description"] forKey:(NSString*)kMDItemDescription];
        }
            
            
        // Which applications have contributed
        if ([md objectForKey:@"applications"])
            [attributes setObject:[md objectForKey:@"applications"] forKey:(NSString*)kMDItemEncodingApplications];  
    }
    /*
    md = [[NSMutableDictionary alloc] init];
    
    // Set up test data for now
    NSMutableDictionary* movieinfo = [[NSMutableDictionary alloc] init];
    
    // The GTIN
    [movieinfo setValue:@"00024543377719" forKey:@"gtin"];
    
    // The title of the movie
    [movieinfo setValue:@"ICE AGE: THE MELTDOWN" forKey:@"title"];
    
    // The movie release date
    [movieinfo setObject:@"2006-11-20" forKey:@"releasedate"];
    
    // Movie owners as publishers
    NSArray* publishers = [[NSArray alloc] initWithObjects:@"20th Century Fox", nil];
    [movieinfo setObject:publishers forKey:@"publishers"];
    
    // Actors as contributors
    NSArray* actors = [[NSArray alloc] initWithObjects:@"Queen Latifah",
                        @"Denis Leary",
                        @"John Leguizamo",
                        @"Jay Leno",
                        @"Will Arnett",
                        @"Carlos Saldanha", nil];
    
    [movieinfo setObject:actors forKey:@"actors"];
    
    // The rating of the movie
    [movieinfo setValue:[NSArray arrayWithObject:@"PG"] forKey:@"rating"];
    
    // Amazon description
    [movieinfo setValue:@"Next Ice Age Movie" forKey:@"kMDItemDescription"];
    
    // Length of movie?
    [movieinfo setValue:@"91 minutes" forKey:@"runtime"];
    
    [md setObject:movieinfo forKey:@"movie"];
    
    // WORD
    NSArray* applications = [[NSArray alloc] initWithObjects:@"RipIt", nil];
    [md setValue:applications forKey:@"applications"];
    */
    
    // Now that we have info, write it out
    // Key relationships:
    
    /*
    Spotlight Key Relationships
    ============================

    movie->title:           kMDItemDisplayName
                            kMDItemTitle
    movie->releaseddate:    kMDItemContentCreationDate
    movie->publishers:      kMDItemPublishers
    movie->actors:          kMDItemContributors
    movie->rating:          kMDItemAudiences
    movie->runtime:         kMDItemDurationSeconds
    movie->description:     kMDItemDescription

    applications:           kMDItemEncodingApplications
    */
    
    [pool release];
}

BOOL GetMetadataForFile(void* thisInterface, NSMutableDictionary* attributes, NSString* contentTypeUTI, NSString* pathToFile)
{
    [attributes setObject:@"public.dvdmedia" forKey:(NSString*)kMDItemContentType];
    
    @try {
        // Generate the fingerprint
        NSString* fingerprint = computeDiscIdentFingerprintForPath(pathToFile);
        [attributes setObject:fingerprint forKey:(NSString*)kMDItemDiscIdentFingerprint];
        
        // Look for the plist
        NSString* jsonFile = [pathToFile stringByAppendingPathComponent:@"_Info.json"];
        NSFileManager* manager = [NSFileManager defaultManager];
        
        // Set the fingerprint
        if (fingerprint != nil) {
            if (![manager fileExistsAtPath:jsonFile]) {
                NSDictionary* dict = [NSDictionary dictionaryWithObject:fingerprint forKey:(NSString*)kMDItemDiscIdentFingerprint];
                NSData* jsonData = [NSData dataWithObjectAsJSON:dict];
                [jsonData writeToFile:jsonFile atomically:NO];
            }
            else {
                // Check to make sure it has our fingerprint
                NSDictionary* dict = [NSDictionary dictionaryWithJSON:[NSString stringWithContentsOfFile:jsonFile]];
                
                if ([dict objectForKey:(NSString*)kMDItemDiscIdentFingerprint] == nil) {
                    NSMutableDictionary* jsonDict = [NSMutableDictionary dictionaryWithDictionary:dict];
                    [jsonDict setObject:fingerprint forKey:(NSString*)kMDItemDiscIdentFingerprint];
                    
                    // Go ahead and write it back out
                    NSData* jsonData = [NSData dataWithObjectAsJSON:[NSDictionary dictionaryWithDictionary:jsonDict]];
                    [manager removeItemAtPath:jsonFile error:nil];           
                    [jsonData writeToFile:jsonFile atomically:YES];                    
                }
            }
        }
        
        [manager release];
        
        // Set the media type
        [attributes setObject:@"public.dvdmedia" forKey:(NSString*)kMDItemDiscIdentFingerprint];
        
        // Now get any additional information from an existing Info.plist file, if one exists
        GetSpotlightInfoFromJSON(pathToFile, attributes);
    }
    @catch (NSException*) {
        return FALSE;
    }
    
    return TRUE;
}
