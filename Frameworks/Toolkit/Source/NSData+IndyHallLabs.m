#import "NSData+IndyHallLabs.h"
#import "openssl/md5.h"
#include <openssl/bio.h>
#include <openssl/evp.h>

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

- (NSString *) base64EncodedString
{
	// Construct an OpenSSL context
	BIO *context = BIO_new(BIO_s_mem());
	
	// Tell the context to encode base64
	BIO *command = BIO_new(BIO_f_base64());
	context = BIO_push(command, context);
	
	// Encode all the data
	BIO_write(context, [self bytes], [self length]);
	BIO_flush(context);
	
	// Get the data out of the context
	char *outputBuffer;
	long outputLength = BIO_get_mem_data(context, &outputBuffer);
	NSString *encodedString = [NSString
							   stringWithCString:outputBuffer
							   length:outputLength];
	
	BIO_free_all(context);
	
	return encodedString;
}

@end
