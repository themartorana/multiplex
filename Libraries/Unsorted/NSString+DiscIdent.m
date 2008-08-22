#import "NSString+DiscIdent.h"
#include <sys/types.h>
#include <sys/stat.h>
#include <openssl/md5.h>
#include <sys/syslimits.h>

@implementation NSString (DiscIdent)

- (NSString*) discidentFingerprintForPath
{
	/*	Do some quick checks.
	 */
	NSFileManager* fileManager = [NSFileManager defaultManager];
	BOOL isDirectory = FALSE;
	if (![fileManager fileExistsAtPath:self isDirectory:&isDirectory] || !isDirectory) {
		return nil;
	}
	NSString* videoPath = [self stringByAppendingPathComponent:@"VIDEO_TS"];
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

@end
