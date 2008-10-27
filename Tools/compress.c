#include <CoreFoundation/CoreFoundation.h>
#include <stdio.h>
#include <zlib.h>

int main(int argc, char* argv[])
{
    CFMutableDataRef data = CFDataCreateMutable(NULL, 0);
    uint8_t buffer[0x1000];
    int32_t bytesRead;
    while (0 < (bytesRead = fread(buffer, 1, sizeof(buffer), stdin))) {
        CFDataAppendBytes(data, buffer, bytesRead);
    }
    
    uLongf outputLength = CFDataGetLength(data);
    void* output = malloc(outputLength);
    if (!output) {
        fprintf(stderr, "Unable to allocate output buffer.");
        return -1;
    }
    
    if (Z_OK != compress(output, &outputLength, CFDataGetBytePtr(data), outputLength)) {
        fprintf(stderr, "Unable to allocate output buffer.");
        return -2;
    };
    
    fwrite(output, 1, outputLength, stdout);
    return 0;
}