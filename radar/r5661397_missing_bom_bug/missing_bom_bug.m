#import <Foundation/Foundation.h>

int main (int argc, const char * argv[])
{
    (void)[[NSAutoreleasePool alloc] init];

    // the test string containing only one UTF-16 character (2-bytes):
    NSString *str = @".";
    
    // The CFStringCreateExternalRepresentation() docs say:
    // 
    // "In the CFData object form, the string can be written to disk
    //  as a file or be sent out over a network. If the encoding of the
    //  characters in the data object is Unicode, the function inserts
    //  a BOM (byte order marker) to indicate endianness."
    NSData *data = (NSData *)CFStringCreateExternalRepresentation
        (NULL, (CFStringRef)str, kCFStringEncodingUTF16BE, 0);

    // expected length is 4 bytes 
    // (that is 2 bytes for the BOM  + 2 bytes for the UTF-16 character)
    // but actual length is 2 bytes (no BOM is present)
    // tested on Mac OS 10.5.1
    NSLog(@"data length: %d", [data length]);
    return 0;
}
