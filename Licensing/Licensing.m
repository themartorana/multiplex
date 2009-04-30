#include "Licensing.h"
#import <openssl/rsa.h>
#import <openssl/sha.h>
#import <sys/types.h>
#import <sys/sysctl.h>
#import <sys/ptrace.h>

static BOOL amIBeingDebugged()
{
#ifdef DEBUG
    return NO;
#else
    int mib[4];
    struct kinfo_proc info;
    size_t size = sizeof(info);
    info.kp_proc.p_flag = 0;
    mib[0] = CTL_KERN;
    mib[1] = KERN_PROC;
    mib[2] = KERN_PROC_PID;
    mib[3] = getpid();
    return (0 == sysctl(mib, sizeof(mib) / sizeof(*mib), &info, &size, NULL, 0)) && (info.kp_proc.p_flag & P_TRACED) != 0;
#endif
}

NSDictionary* loadParameters()
{
    RSA* rsaKey = RSA_new();
    
#ifndef DEBUG
    ptrace(PT_DENY_ATTACH, 0, 0, 0);
#endif
    
    /*  Create the public key.
     */
    //0xA0, 0x13, 0x8C, 0x80, 0xEE, 0x28, 0x32, 0x61 ^ 'M', 
    //0x0B, 0x55, 0x93, 0x3A, 0x92, 0xB1, 0x73, 0xE7 ^ 'u', 
    //0xD9, 0xC5, 0x9E, 0xDD, 0x68, 0x2F, 0x55, 0x4B ^ 'l', 
    //0xE2, 0x0E, 0x27, 0x3C, 0xD5, 0x60, 0x07, 0x13 ^ 't', 
    //0x3D, 0x07, 0x9B, 0xF2, 0x05, 0xC6, 0x85, 0xEE ^ 'i', 
    //0x47, 0xA6, 0x72, 0x9B, 0x8E, 0xD5, 0x20, 0x8B ^ 'p', 
    //0x96, 0xBD, 0x3C, 0xDC, 0x50, 0x17, 0x03, 0xD5 ^ 'l', 
    //0xC8, 0xD9, 0xBE, 0xF1, 0xA2, 0x0B, 0x48, 0xAA ^ 'e', 
    //0xC4, 0xD6, 0xC2, 0x58, 0x15, 0xA1, 0xDD, 0x62 ^ 'x', 
    //0x82, 0x4A, 0x13, 0x23, 0x5B, 0xAB, 0x47, 0xE4 ^ ' ', 
    //0x9D, 0xBE, 0x0E, 0xF1, 0x0D, 0x41, 0x56, 0x56 ^ '0', 
    //0xD0, 0x75, 0xB6, 0x69, 0x83, 0x79, 0x03, 0x33 ^ '.', 
    //0x25, 0x24, 0xC0, 0x9D, 0x9A, 0x97, 0x52, 0x01 ^ '9', 
    //0xF4, 0x64, 0xC4, 0x96, 0x56, 0x0A, 0xC9, 0xB7 ^ '.', 
    //0x52, 0xBD, 0x22, 0xC0, 0x73, 0xA3, 0x4A, 0xF9 ^ '0', 
    //0xED, 0xE4, 0xE2, 0xE7, 0x95, 0x8E, 0x8A, 0x71 ^ ' ',
    
    unsigned char RSA_N[] = {
        0xAB, 0x51, 0x97, 0xDA, 0x0A, 0xCE, 0xCF, 0x66 ^ 'M',
        0xA5, 0x28, 0xD0, 0x52, 0x3C, 0xFA, 0xF4, 0xE0 ^ 'u',
        0x03, 0x6B, 0xB2, 0xEE, 0x76, 0x53, 0xC5, 0xA7 ^ 'l',
        0xEA, 0x10, 0xC3, 0xB1, 0x68, 0x33, 0x2C, 0x00 ^ 't',
        0xF7, 0x94, 0x2B, 0x26, 0x67, 0x18, 0x81, 0x84 ^ 'i',
        0x7D, 0xD9, 0xEE, 0x7D, 0xA6, 0x9D, 0x35, 0xE8 ^ 'p',
        0xEF, 0x7F, 0x4C, 0x5E, 0x00, 0x11, 0xC1, 0x81 ^ 'l',
        0x45, 0x88, 0xF5, 0x2E, 0x97, 0x64, 0x51, 0x07 ^ 'e',
        0xEF, 0x93, 0xFD, 0x83, 0x93, 0x4E, 0xB5, 0x34 ^ 'x',
        0x32, 0x03, 0x80, 0x49, 0xA1, 0xCE, 0x02, 0x58 ^ ' ',
        0x97, 0xEA, 0xF0, 0x75, 0x48, 0xC5, 0xCE, 0xCC ^ '1',
        0x52, 0xDC, 0x1D, 0x28, 0xDB, 0x75, 0xEA, 0xC4 ^ '.',
        0xF7, 0x29, 0x09, 0x65, 0x80, 0xDD, 0x71, 0x4C ^ '0',
        0x66, 0x53, 0x36, 0x1F, 0xED, 0xF1, 0x6D, 0x0A ^ '.',
        0x14, 0x7E, 0x04, 0x5D, 0xBF, 0x25, 0xE0, 0xF4 ^ '0',
        0x44, 0x1D, 0x28, 0x84, 0xB2, 0xC5, 0x77, 0x17 ^ ' ',
    };
    char salt[] = { 'M', 'u', 'l', 't', 'i', 'p', 'l', 'e', 'x', ' ', '1', '.', '0', '.', '0', ' ', 0 };
    for (int i = 0, imax = strlen(salt); i < imax; i++) {
        RSA_N[((i + 1) << 3) - 1 + amIBeingDebugged()] ^= salt[i];
    }
    rsaKey->n = BN_bin2bn(RSA_N, sizeof(RSA_N), NULL);
    
    /*  Create the exponent.
     */
    unsigned char RSA_E[] = {
        0x03
    };
    rsaKey->e = BN_bin2bn(RSA_E, sizeof(RSA_E), NULL);
    
    /*  Load the license file, and check it for basic validity.
     */
    CFMutableDictionaryRef myDict = nil;
    CFDataRef data;
    SInt32 errorCode;
    NSString* licenseFile = [[NSBundle mainBundle] pathForResource:@"license" ofType:@"plist"];
    if (!licenseFile || !CFURLCreateDataAndPropertiesFromResource(kCFAllocatorDefault, (CFURLRef)[NSURL fileURLWithPath:licenseFile], &data, NULL, NULL, &errorCode) || errorCode) {
        RSA_free(rsaKey);
        return NULL;
    } else {
        CFStringRef errorString = NULL;
        myDict = (CFMutableDictionaryRef)CFPropertyListCreateFromXMLData(kCFAllocatorDefault, data, kCFPropertyListMutableContainers, &errorString);
        CFRelease(data);
        data = NULL;
        if (errorString || CFDictionaryGetTypeID() != CFGetTypeID(myDict) || !CFPropertyListIsValid(myDict, kCFPropertyListXMLFormat_v1_0)) {
            CFRelease(myDict);
            RSA_free(rsaKey);
            return NULL;
        }
    }
    
    /*  Extract the signature.
     */
    unsigned char sigBytes[128];
    if (!CFDictionaryContainsKey(myDict, CFSTR("Signature"))) {
        CFRelease(myDict);
        RSA_free(rsaKey);
        return NULL;
    } else {
        CFDataRef sigData = CFDictionaryGetValue(myDict, CFSTR("Signature"));
        CFDataGetBytes(sigData, CFRangeMake(0, 128), sigBytes);
        CFDictionaryRemoveValue(myDict, CFSTR("Signature"));
    }
    
    /*  Decrypt the signature.
     */
    unsigned char checkDigest[128] = {0};
    if (RSA_public_decrypt(128, sigBytes, checkDigest, rsaKey, RSA_PKCS1_PADDING) != SHA_DIGEST_LENGTH) {
        CFRelease(myDict);
        RSA_free(rsaKey);
        return NULL;
    } else {
        RSA_free(rsaKey);
        rsaKey = NULL;
    }
    
    /*  Get the number of elements, Load the keys and build up the key array.
     */
    CFIndex count = CFDictionaryGetCount(myDict);
    CFMutableArrayRef keyArray = CFArrayCreateMutable(kCFAllocatorDefault, count, NULL);
    CFStringRef keys[count];
    CFDictionaryGetKeysAndValues(myDict, (const void**)&keys, NULL);
    for (int i = 0; i < count; i++) {
        CFArrayAppendValue(keyArray, keys[i]);
    }
    
    /*  Sort the array, so that we'll have consistent hashes.
     */
    int context = kCFCompareCaseInsensitive;
    CFArraySortValues(keyArray, CFRangeMake(0, count), (CFComparatorFunction)CFStringCompare, &context);
    
    /*  Hash the keys and values.
     */
    SHA_CTX ctx;
    SHA1_Init(&ctx);
    for (int i = 0; i < count; i++) {
        char *valueBytes;
        int valueLengthAsUTF8;
        CFStringRef key = CFArrayGetValueAtIndex(keyArray, i);
        CFStringRef value = CFDictionaryGetValue(myDict, key);
        
        // Account for the null terminator
        valueLengthAsUTF8 = CFStringGetMaximumSizeForEncoding(CFStringGetLength(value), kCFStringEncodingUTF8) + 1;
        valueBytes = (char *)malloc(valueLengthAsUTF8);
        CFStringGetCString(value, valueBytes, valueLengthAsUTF8, kCFStringEncodingUTF8);
        SHA1_Update(&ctx, valueBytes, strlen(valueBytes));
        free(valueBytes);
    }
    unsigned char digest[SHA_DIGEST_LENGTH];
    SHA1_Final(digest, &ctx);
    
    if (keyArray != nil) {
        CFRelease(keyArray);
    }
    
    /*  Check if the signature is a match.
     */
    for (int i = 0; i < SHA_DIGEST_LENGTH; i++) {
        if (checkDigest[i] ^ digest[i]) {
            CFRelease(myDict);
            return NULL;
        }
    }
    
    NSString* expires = (NSString*)CFDictionaryGetValue(myDict, CFSTR("Expires"));
    NSDate* expiresOn = nil;
    if (expires && (!(expiresOn = [NSDate dateWithString:expires]) || (expiresOn == [[NSDate date] earlierDate:expiresOn]))) {
        CFRelease(myDict);
        return NULL;
    }
    
    return (NSDictionary*)myDict;
}
