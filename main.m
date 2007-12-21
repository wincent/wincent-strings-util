//
//  main.m
//  wincent-strings-util
//
//  Copyright 2005-2007 Wincent Colaiuta.
//  Derived from Omni stringsUtil, Copyright 2002 Omni Development, Inc.
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.

#pragma mark -
#pragma mark Macros

#define WO_LEFT_DELIMITER   0x00ab  /* "Left-pointing double angle quotation mark" */
#define WO_RIGHT_DELIMITER  0x00bb  /* "Right-pointing double angle quotation mark" */

#pragma mark -
#pragma mark Embedded information for what(1)

// embed with tag
#define WO_TAGGED_RCSID(msg, tag) \
        static const char *const rcsid_ ## tag[] __attribute__((used)) = { (char *)rcsid_ ## tag, "\100(#)" msg }

// use as string
#define WO_RCSID_STRING(tag) (rcsid_ ## tag[1] + 4)

WO_TAGGED_RCSID("Copyright 2002 Omni Development, Inc.", omni_copyright);
WO_TAGGED_RCSID("Copyright 2005-2007 Wincent Colaiuta.", copyright);

#if defined(__ppc__)
WO_TAGGED_RCSID("Architecture: PowerPC (ppc)", architecture);
#elif defined(__ppc64__)
WO_TAGGED_RCSID("Architecture: PowerPC (ppc64)", architecture);
#elif defined(__i386__)
WO_TAGGED_RCSID("Architecture: Intel (i386)", architecture);
#elif defined(__x86_64__)
WO_TAGGED_RCSID("Architecture: Intel (x86_64)", architecture);
#endif

WO_TAGGED_RCSID("Version: 1.2", version);
WO_TAGGED_RCSID("wincent-strings-util", productname);

#pragma mark -

@interface NSScanner (CharacterAdditions)

- (BOOL)peekCharacter:(unichar *)value;
- (BOOL)scanCharacter:(unichar *)value;
- (BOOL)scanComment:(NSString **)value;
- (BOOL)scanQuotedString:(NSString **)value;
- (BOOL)scanUnquotedString:(NSString **)value;
- (NSString *)scanLocationDescription;
- (void)complain:(NSString *)reason;

@end

@implementation NSScanner (CharacterAdditions)

- (BOOL)peekCharacter:(unichar *)value
{
    NSParameterAssert(value != NULL);
    unsigned scanLocation   = [self scanLocation];
    NSString *string        = [self string];
    if (scanLocation >= [string length])    // was a bug (couldn't peek at the last character)
        return NO;
    *value = [string characterAtIndex:scanLocation];
    return YES;
}

- (BOOL)scanCharacter:(unichar *)value
{
    unsigned scanLocation   = [self scanLocation];
    NSString *string        = [self string];
    if (scanLocation >= [string length])    // was a bug (couldn't peek at the last character)
        return NO;
    if (value != NULL)
        *value = [string characterAtIndex:scanLocation];
    [self setScanLocation:scanLocation + 1];
    return YES;
}

- (BOOL)scanComment:(NSString **)value
{
    unsigned scanLocation = [self scanLocation];
    if ([self scanString:@"//" intoString:NULL])
    {
        [self scanUpToString:@"\n" intoString:value];
        [self scanString:@"\n" intoString:NULL];
        return YES;
    }

    if ([self scanString:@"/*" intoString:NULL])
    {
        [self scanUpToString:@"*/" intoString:value];
        if ([self scanString:@"*/" intoString:NULL])
            return YES;
    }

    [self setScanLocation:scanLocation]; // reset
    return NO;
}

- (BOOL)scanQuotedString:(NSString **)value
{
    unsigned scanLocation = [self scanLocation];
    NSString *tempString;
    if (![self scanString:@"\"" intoString:&tempString]) return NO;

    NSCharacterSet *specials = [NSCharacterSet characterSetWithCharactersInString:@"\r\n\"\\"];
    NSMutableString *result = [NSMutableString stringWithString:tempString];

    while (![self isAtEnd])
    {
        if ([self scanUpToCharactersFromSet:specials intoString:&tempString])
            [result appendString:tempString];

        unichar character;
        if (![self scanCharacter:&character]) goto bail;
        [result appendFormat:@"%C", character];

        switch (character)
        {
            case '\"': // found closing quote
                if (value != NULL) *value = [NSString stringWithString:result];
                return YES;
            case '\\': // found backslash, expect escaped next character
                if (![self scanCharacter:&character]) goto bail;
                [result appendFormat:@"%C", character];
                break;
            default:   // found literal linefeed or carriage return
                goto bail;
        }
    }

bail:
    [self setScanLocation:scanLocation]; // reset
    return NO;
}

- (BOOL)scanUnquotedString:(NSString **)value
{
    return ([self scanCharactersFromSet:[NSCharacterSet alphanumericCharacterSet] intoString:value]);
}

- (NSString *)scanLocationDescription
{
    // save state
    unsigned        originalLocation        = [self scanLocation];
    NSCharacterSet  *charactersToBeSkipped  = [self charactersToBeSkipped];
    NSString        *lastLine               = @"\n";
    unsigned        lineStartLocation       = 0;
    unsigned        lineCount               = 0;
    [self setScanLocation:0];
    [self setCharactersToBeSkipped:nil];
    while (([self scanLocation] <= originalLocation) && (![self isAtEnd]))
    {
        lineStartLocation = [self scanLocation];
        if (![self scanUpToString:@"\n" intoString:&lastLine])
            lastLine = @"\n";
        if ([self scanString:@"\n" intoString:NULL])
            lineCount++;
    }

    // restore state
    [self setScanLocation:originalLocation];
    [self setCharactersToBeSkipped:charactersToBeSkipped];

    return [NSString stringWithFormat:@"line %d character %d (location %d):\n%@",
        lineCount, (originalLocation - lineStartLocation), originalLocation, lastLine];
}

- (void)complain:(NSString *)reason
{
    [NSException raise:NSGenericException format:@"%@ at %@", reason, [self scanLocationDescription]];
}

@end

#pragma mark -
#pragma mark Functions

/*! Parse the contents of a strings file (passed as an NSString, \p contents). */
NSArray *parse(NSString *contents)
{
    NSCParameterAssert(contents != nil);
    NSCharacterSet *whitespace      = [NSCharacterSet characterSetWithCharactersInString:@"\n\r\t "];
    NSMutableArray *comments        = [NSMutableArray array];
    NSMutableArray *entries         = [NSMutableArray array];
    NSScanner      *stringScanner   = [NSScanner scannerWithString:contents];
    [stringScanner setCharactersToBeSkipped:nil];
    [stringScanner setCaseSensitive:NO];
    while (![stringScanner isAtEnd])
    {
        [stringScanner scanCharactersFromSet:whitespace intoString:NULL];
        unichar character;
        if (![stringScanner peekCharacter:&character]) break;

        if (character == '/')       // try to scan comment
        {
            NSString *comment = nil;
            if (![stringScanner scanComment:&comment])
                [stringScanner complain:@"Invalid comment"];
            [comments addObject:comment];
        }
        else                        // try to scan 'key = value' pair
        {
            NSString *key, *value;

            if (character == '\"')  // try to scan quoted string
            {
                if (![stringScanner scanQuotedString:&key])
                    [stringScanner complain:@"Invalid key"];
            }
            else                    // try to scan unquoted string
            {
                if (![stringScanner scanUnquotedString:&key])
                    [stringScanner complain:@"Invalid key"];
            }

            // code common to quoted and unquoted strings
            [stringScanner scanCharactersFromSet:whitespace intoString:NULL];

            if (![stringScanner scanString:@"=" intoString:NULL])
                [stringScanner complain:@"Can't find = between key and value"];

            [stringScanner scanCharactersFromSet:whitespace intoString:NULL];

            if (![stringScanner scanQuotedString:&value])
                [stringScanner complain:@"Invalid value"];

            [stringScanner scanCharactersFromSet:whitespace intoString:NULL];

            if (![stringScanner scanString:@";" intoString:NULL])
                [stringScanner complain:@"Missing ;"];

            [entries addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                key,                                @"key", 
                value,                              @"value", 
                [NSArray arrayWithArray:comments],  @"comments", nil]];
            [comments removeAllObjects];
        }
    }
    return entries;
}

/*! Merge base entries and merge entries. */
NSArray *merge(NSArray *baseEntries, NSArray *mergeEntries)
{
    NSCParameterAssert(baseEntries != nil);
    NSCParameterAssert(mergeEntries != nil);

    __attribute__((unused))
    NSAutoreleasePool   *pool               = [[NSAutoreleasePool alloc] init];
    NSMutableArray      *results            = [NSMutableArray arrayWithCapacity:[baseEntries count]];
    NSMutableSet        *baseSet            = [NSMutableSet set];
    NSMutableDictionary *mergeDictionary    = [NSMutableDictionary dictionary];

    // convert baseEntries array into a set, for fast look-up
    for (NSDictionary *entry in baseEntries)
        [baseSet addObject:[entry objectForKey:@"key"]];

    // convert mergeEntries array into a dictionary, ignoring comments
    for (NSDictionary *entry in mergeEntries)
    {
        NSString *key = [entry objectForKey:@"key"];
        [mergeDictionary setObject:[entry objectForKey:@"value"] forKey:key];

        // warn about keys that will not appear in output
        if (![baseSet containsObject:key])
            fprintf(stderr, ":: warning: key '%s' in merge but not in base (omitted from output)\n", [key UTF8String]);
    }

    // merge (start with "base"; translated keys from "merge" added to output)
    for (NSDictionary *entry in baseEntries)
    {
        NSMutableDictionary *mutableEntry   = [entry mutableCopy];
        NSDictionary        *mergeValue     = [mergeDictionary objectForKey:[mutableEntry objectForKey:@"key"]];

        if (mergeValue)
            [mutableEntry setObject:mergeValue forKey:@"value"];
        else
            fprintf(stderr, ":: warning: missing key '%s' in merge (added to output)\n",
                    [[mutableEntry objectForKey:@"key"] UTF8String]);

        [results addObject:[NSDictionary dictionaryWithDictionary:mutableEntry]];
    }

    return [[NSArray alloc] initWithArray:results];
}

/*! Format entries for output as strings file. */
NSString *format(NSArray *entries)
{
    NSCParameterAssert(entries != nil);
    NSMutableString *resultString = [NSMutableString string];
    for (NSDictionary *entry in entries)
    {
        for (NSString *comment in [entry objectForKey:@"comments"])
            [resultString appendFormat:@"/*%@*/\n", comment];

        [resultString appendFormat:@"%@ = %@;\n\n", [entry objectForKey:@"key"], [entry objectForKey:@"value"]];
    }
    return [NSString stringWithString:resultString];
}

/*! Write \p string to file \p path using NSUnicodeStringEncoding. If \p path is nil, prints to standard out. Returns YES on success and NO if an error occurs. */
BOOL output(NSString *string, NSString *path)
{
    NSCParameterAssert(string != nil);
    NSData *data = [string dataUsingEncoding:NSUnicodeStringEncoding];
    if (!data)
    {
        fprintf(stderr, ":: error: Encoding failure\n");
        return NO;
    }
    if (path)
    {
        if ([data writeToFile:path atomically:YES])
            return YES;
    }
    else // no output path, write to standard out
    {
        if (write(STDOUT_FILENO, [data bytes], [data length]) != -1)
            return YES;
        else
            perror("write()");
    }
    return NO;
}

/*! Check the file at \p path for a UTF-16 byte order marker (BOM) and warn if not found appropriate. */
void checkUTF16(NSString *path)
{
    // http://en.wikipedia.org/wiki/Byte_Order_Mark
    NSCParameterAssert(path != nil);

    NSData *data = [NSData dataWithContentsOfFile:path];
    if (data && ([data length] >= 2))
    {
        UInt8 *BOM = (UInt8 *)[data bytes];
        if ((BOM[0] == 0xfe) && (BOM[1] == 0xff))
            return;     // probably UTF-16 big-endian
        else if ((BOM[0] == 0xff) && (BOM[1] == 0xfe))
            return;     // probably UTF-16 little-endian
        else
        {
            // no UTF-16 BOM found, check for UTF-8 BOM
            if ([data length] >= 3)
            {
                if ((BOM[0] == 0xef) && (BOM[1] == 0xbb) && (BOM[2] == 0xbf))
                    fprintf(stderr, ":: warning: possible UTF-8 BOM found in file %s\n", [path UTF8String]);
                else
                    fprintf(stderr, ":: warning: unable to determine encoding of file %s (no BOM found)\n", [path UTF8String]);
            }
            else
                fprintf(stderr, ":: warning: unable to determine encoding of file %s (file too short)\n", [path UTF8String]);
        }
    }
    else
        fprintf(stderr, ":: warning: unable to check file %s for BOM (file is unreadable or too short)\n", [path UTF8String]);
}

int main(int argc, const char * argv[])
{
    NSAutoreleasePool   *pool           = [[NSAutoreleasePool alloc] init];
    int                 exitCode        = EXIT_FAILURE;

    // process arguments
    NSUserDefaults      *arguments      = [NSUserDefaults standardUserDefaults];
    NSString            *infoPath       = [arguments stringForKey:@"info"];
    NSString            *stringsPath    = [arguments stringForKey:@"strings"];
    NSString            *basePath       = [arguments stringForKey:@"base"];
    NSString            *mergePath      = [arguments stringForKey:@"merge"];
    NSString            *outputPath     = [arguments stringForKey:@"output"];

    // usage 1: wincent-strings-util -base basepath [-merge mergepath] [-output outputpath]
    if (basePath)
    {
        checkUTF16(basePath);   // warn if it doesn't look like UTF-16
        NSString        *baseStrings    = [NSString stringWithContentsOfFile:basePath];
        NSArray         *baseEntries    = nil;
        @try
        {
            baseEntries = parse(baseStrings);
        }
        @catch (NSException *exception)
        {
            fprintf(stderr, ":: error: Parse failure for %s: %s\n", [basePath UTF8String], [[exception reason] UTF8String]);
            exit(EXIT_FAILURE);
        }

        if (mergePath)
        {
            checkUTF16(mergePath);      // warn if it doesn't look like UTF-16
            NSString    *mergeStrings   = [NSString stringWithContentsOfFile:mergePath];
            NSArray     *mergeEntries   = nil;
            @try
            {
                mergeEntries = parse(mergeStrings);
            }
            @catch (NSException *exception)
            {
                fprintf(stderr, ":: error: Parse failure for %s: %s\n", [mergePath UTF8String], [[exception reason] UTF8String]);
                exit(EXIT_FAILURE);
            }
            baseEntries = merge(baseEntries, mergeEntries);
        }
        NSString    *outputString = format(baseEntries);
        if (output(outputString, outputPath)) exitCode = EXIT_SUCCESS;
    }
    // usage 2: wincent-strings-util -info plistpath -strings stringspath
    else if (infoPath && stringsPath)
    {
        NSDictionary    *plist      = [NSDictionary dictionaryWithContentsOfFile:infoPath];
        NSMutableString *strings    = [NSMutableString stringWithContentsOfFile:stringsPath
                                                                       encoding:NSUnicodeStringEncoding
                                                                          error:NULL];
        if (!plist)
            fprintf(stderr, ":: error: Failure reading %s\n", [infoPath UTF8String]);
        else if (!strings)
            fprintf(stderr, ":: error: Failure reading %s\n", [stringsPath UTF8String]);
        else // all good
        {
            checkUTF16(stringsPath);    // warn if doesn't look like UTF-16
            NSEnumerator    *enumerator = [plist keyEnumerator];
            NSString        *key        = nil;
            while ((key = [enumerator nextObject]))
            {
                NSString *replacement = [plist objectForKey:key];
                if (!replacement  || ![replacement isKindOfClass:[NSString class]]) continue;
                NSString *needle = [NSString stringWithFormat:@"%C%@%C", WO_LEFT_DELIMITER, key, WO_RIGHT_DELIMITER];
                (void)[strings replaceOccurrencesOfString:needle
                                               withString:replacement
                                                  options:NSLiteralSearch
                                                    range:NSMakeRange(0, [strings length])];
            }
            if (output(strings, outputPath)) exitCode = EXIT_SUCCESS;
        }
    }
    else    // faulty arguments supplied, show usage
    {
        // print legal stuff for compliance with Omni Source License
        fprintf(stderr, 
                //--------------------------------- 80 columns --------------------------------->| 
                "%s\n"                                                                  // product name
                "http://strings.wincent.com/\n"
                "%s\n"                                                                  // version
                "\n"
                "%s\n"                                                                  // copyright
                "Based on software developed by Omni Development\n"
                "%s\n"                                                                  // omni copyright
                "\n"
                "Usage:\n"
                "  %s -base basepath [-merge mergepath] [-output outputpath]\n"
                "  %s -info plistpath -strings stringspath [-output outputpath]\n", 
                WO_RCSID_STRING(productname),       WO_RCSID_STRING(version),       WO_RCSID_STRING(copyright),     
                WO_RCSID_STRING(omni_copyright),    WO_RCSID_STRING(productname),   WO_RCSID_STRING(productname));
    }

    [pool drain];
    return exitCode;
}
