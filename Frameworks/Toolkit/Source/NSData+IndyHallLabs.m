#import "NSData+IndyHallLabs.h"
#import "openssl/md5.h"

@implementation NSData (IndyHallLabs)

- (NSString*) IHLFingerprint
{
    /*  Generate the fingerprint.
     */
    unsigned char fingerprint[MD5_DIGEST_LENGTH];
    MD5_CTX ctx;
    MD5_Init(&ctx);
    MD5_Update(&ctx, [self bytes], [self length]);
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
