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

// other headers
#import "NSScanner+WOAdditions.h"
#import "WOLocalizable.h"

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
#pragma mark Functions

//! Parse the contents of a strings file.
//! Note that this is passed as an NSString, \p contents, which is the file <em>contents</em> and not a path to the file.
NSArray *parse(NSString *contents)
{
    NSCParameterAssert(contents != nil);
    NSMutableArray *comments    = [NSMutableArray array];
    NSMutableArray *entries     = [NSMutableArray array];
    NSScanner      *scanner     = [NSScanner scannerWithString:contents];
    [scanner setCharactersToBeSkipped:nil];
    [scanner setCaseSensitive:NO];
    while (![scanner isAtEnd])
    {
        unichar character;
        [scanner skipWhitespace];
        if (![scanner peekCharacter:&character])
            break;

        if (character == '/')       // try to scan comment
        {
            NSString *comment = nil;
            if (![scanner scanComment:&comment])
                [scanner complain:@"Invalid comment"];
            [comments addObject:comment];
        }
        else                        // try to scan 'key = value' pair
        {
            NSString *key, *value;
            if (character == '\"')  // try to scan quoted string
            {
                if (![scanner scanQuotedString:&key])
                    [scanner complain:@"Invalid key"];
            }
            else                    // try to scan unquoted string
            {
                if (![scanner scanUnquotedString:&key])
                    [scanner complain:@"Invalid key"];
            }

            // code common to quoted and unquoted strings
            [scanner skipWhitespace];
            if (![scanner scanString:@"=" intoString:NULL])
                [scanner complain:@"Can't find = between key and value"];
            [scanner skipWhitespace];
            if (![scanner scanQuotedString:&value])
                [scanner complain:@"Invalid value"];
            [scanner skipWhitespace];
            if (![scanner scanString:@";" intoString:NULL])
                [scanner complain:@"Missing ;"];

            [entries addObject:[WOLocalizable localizableWithKey:key value:value comments:comments]];
            [comments removeAllObjects];
        }
    }
    return entries;
}

//! Extract the entries which are present in \p base (the main development language) but either missing or not translated in
//! \p target (the target localization).
//! This is intended to help incremental localization; it can be used to generate a strings file that contains only the new
//! strings that need to be translated.
NSArray *extract(NSArray *base, NSArray *target)
{
    NSCParameterAssert(base != nil);
    NSCParameterAssert(target != nil);

    __attribute__((unused)) NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSMutableArray      *results            = [NSMutableArray arrayWithCapacity:base.count];
    NSMutableDictionary *targetDictionary   = [NSMutableDictionary dictionary];

    // convert target array into a dictionary for ease of look-up, ignoring comments
    for (WOLocalizable *entry in target)
        [targetDictionary setObject:entry.value forKey:entry.key];

    for (WOLocalizable *entry in base)
    {
        NSString *translated = [targetDictionary objectForKey:entry.key];
        if (!translated || translated == entry.value)
            [results addObject:entry];
    }
    return results;
}

//! Combine two strings files into one using a simple additive algorithm rather than a merge.
//! This is intended to be used in conjuncton with the extract() function; given an old strings file and a partial strings file
//! previously extracted with extract(), combine them to form a new strings file.
//! Unlike a merge operation, the two strings files are expected to have no overlap, but if they do the entry from \p target will
//! take precedence and a warning will be printed to the console. This is to enable workflows wherein untranslated strings are
//! present in a localization and are extracted (using extract()), then translated, and then used to produce an updated
//! result.
NSArray *combine(NSArray *base, NSArray *target)
{
    NSCParameterAssert(base != nil);
    NSCParameterAssert(target != nil);

    __attribute__((unused)) NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSMutableArray *results = [target mutableCopy];
    NSMutableSet *keys = [NSMutableSet set];

    // store keys in a set for fast lookup
    for (WOLocalizable *entry in target)
        [keys addObject:entry.key];

    BOOL duplicatesFound = NO;
    for (WOLocalizable *entry in base)
    {
        if ([keys containsObject:entry.key])
        {
            fprintf(stderr, ":: warning: duplicate key '%s'\n", [entry.key UTF8String]);
            continue;
        }

        [results addObject:entry];
        [keys addObject:entry.key];
    }
    return results;
}

//! Merge base entries and merge entries.
NSArray *merge(NSArray *baseEntries, NSArray *mergeEntries)
{
    NSCParameterAssert(baseEntries != nil);
    NSCParameterAssert(mergeEntries != nil);

    __attribute__((unused)) NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSMutableArray      *results            = [NSMutableArray arrayWithCapacity:[baseEntries count]];
    NSMutableSet        *baseSet            = [NSMutableSet set];
    NSMutableDictionary *mergeDictionary    = [NSMutableDictionary dictionary];

    // convert baseEntries array into a set, for fast look-up
    for (WOLocalizable *entry in baseEntries)
        [baseSet addObject:entry.key];

    // convert mergeEntries array into a dictionary, ignoring comments
    for (WOLocalizable *entry in mergeEntries)
    {
        [mergeDictionary setObject:entry.value forKey:entry.key];

        // warn about keys that will not appear in output
        if (![baseSet containsObject:entry.key])
            fprintf(stderr, ":: warning: key '%s' in merge but not in base (omitted from output)\n", [entry.key UTF8String]);
    }

    // merge (start with "base"; translated keys from "merge" are added to output)
    for (WOLocalizable *entry in baseEntries)
    {
        // we're going to mutate the entry so make a copy of it first (not strictly necessary here, but it's good practice)
        entry = [entry copy];
        NSString *value = [mergeDictionary objectForKey:entry.key];
        if (value)
            entry.value = value;
        else
            fprintf(stderr, ":: warning: missing key '%s' in merge (added to output)\n", [entry.key UTF8String]);

        [results addObject:entry];
    }
    return results;
}

//! Format entries for output as strings file.
NSString *format(NSArray *entries)
{
    NSCParameterAssert(entries != nil);
    NSMutableString *resultString = [NSMutableString string];
    for (WOLocalizable *entry in entries)
    {
        for (NSString *comment in entry.comments)
            [resultString appendFormat:@"/*%@*/\n", comment];
        [resultString appendFormat:@"%@ = %@;\n\n", entry.key, entry.value];
    }
    return resultString;
}

//! Check the file at \p path for a UTF-16 byte order marker (BOM) and warn if nothing appropriate found.
void checkUTF16(NSString *path)
{
    // See: <http://en.wikipedia.org/wiki/Byte_Order_Mark>
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

//! Tries to read the strings file at \p path and returns an array of localization entries found in the file.
//! Immediately bails if the file could not be read or parsed.
NSArray *input_or_die(NSString *path)
{
    NSCParameterAssert(path != nil);
    checkUTF16(path); // warn if it doesn't look like UTF-16
    NSString    *contents   = [NSString stringWithContentsOfFile:path];
    if (!contents)
    {
        fprintf(stderr, ":: error: Failed to read file %s\n", [path UTF8String]);
        exit(EXIT_FAILURE);
    }

    NSArray *entries = nil;
    @try
    {
        entries = parse(contents);
    }
    @catch (NSException *exception)
    {
        fprintf(stderr, ":: error: Parse failure for %s: %s\n", [path UTF8String], [[exception reason] UTF8String]);
        exit(EXIT_FAILURE);
    }
    return entries;
}

//! Write \p string to file \p path using NSUnicodeStringEncoding.
//! If \p path is nil, prints to standard out.
//! Returns YES on success and NO if an error occurs.
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

//! Show legal and copyright information.
void legal(void)
{
    fprintf(stderr,
            "%s\n"                              // product name
            "http://strings.wincent.com/\n"
            "%s\n"                              // version
            "\n"
            "%s\n"                              // copyright
            "%s\n",                             // omni copyright
            WO_RCSID_STRING(productname),       WO_RCSID_STRING(version),       WO_RCSID_STRING(copyright),
            WO_RCSID_STRING(omni_copyright));
}

void usage(void)
{
    fprintf(stderr,
            "Usage:\n"
            "  %s -base basepath [-merge mergepath | -extract extractpath | -combine combinepath] [-output outputpath]\n"
            "  %s -info plistpath -strings stringspath [-output outputpath]\n",
            WO_RCSID_STRING(productname),   WO_RCSID_STRING(productname));
}

void show_usage_and_die(const char *message)
{
    fprintf(stderr, ":: error: %s\n", message);
    usage();
    exit(EXIT_FAILURE);
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
    NSString            *extractPath    = [arguments stringForKey:@"extract"];
    NSString            *combinePath    = [arguments stringForKey:@"combine"];
    NSString            *outputPath     = [arguments stringForKey:@"output"];

    // usage 1: wincent-strings-util -base basepath [-merge mergepath] [-output outputpath]
    // usage 2: wincent-strings-util -base basepath [-extract extractpath] [-output outputpath]
    // usage 3: wincent-strings-util -base basepath [-combine combinepath] [-output outputpath]
    if (basePath)
    {
        if ((mergePath && extractPath) || (mergePath && combinePath) || (extractPath && combinePath))
            show_usage_and_die("the -merge, -extract and -combine options are mutually exclusive");
        else if (infoPath || stringsPath)
            show_usage_and_die("the -info and -strings options are not allowed with -base");

        // merge, extract or combine
        NSArray *base = input_or_die(basePath);
        NSArray *result = nil;
        if (mergePath)
            result = merge(base, input_or_die(mergePath));
        else if (extractPath)
            result = extract(base, input_or_die(extractPath));
        else if (combinePath)
            result = combine(base, input_or_die(combinePath));

        // write out the result
        NSCAssert(result != nil, @"result should be non-nil");
        if (output(format(result), outputPath))
            exitCode = EXIT_SUCCESS;
    }
    // usage 4: wincent-strings-util -info plistpath -strings stringspath
    else if (infoPath || stringsPath)
    {
        if (!infoPath)
            show_usage_and_die("the -info option is required with -strings");
        else if (!stringsPath)
            show_usage_and_die("the -strings option is required with -info");
        else if (mergePath || combinePath || extractPath)
            show_usage_and_die("the -merge, -extract or -combine options are not allowed with -info and -strings");

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
                if (!replacement  || ![replacement isKindOfClass:[NSString class]])
                    continue;
                NSString *needle = [NSString stringWithFormat:@"%C%@%C", WO_LEFT_DELIMITER, key, WO_RIGHT_DELIMITER];
                (void)[strings replaceOccurrencesOfString:needle
                                               withString:replacement
                                                  options:NSLiteralSearch
                                                    range:NSMakeRange(0, [strings length])];
            }
            if (output(strings, outputPath))
                exitCode = EXIT_SUCCESS;
        }
    }
    else    // no arguments supplied, show extended usage (with legal info)
    {
        legal();
        fprintf(stderr, "\n");
        usage();
    }

    [pool drain];
    return exitCode;
}
