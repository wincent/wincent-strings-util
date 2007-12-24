//
// NSScanner+WOAdditions.m
// wincent-strings-util
//
// Created by Wincent Colaiuta on 21 December 2007.
// Copyright 2007 Wincent Colaiuta.

// category header
#import "NSScanner+WOAdditions.h"

#pragma mark -
#pragma mark Macros

#define WO_LEFT_DELIMITER   0x00ab  /* "Left-pointing double angle quotation mark" */
#define WO_RIGHT_DELIMITER  0x00bb  /* "Right-pointing double angle quotation mark" */

@implementation NSScanner (WOAdditions)

- (BOOL)peekCharacter:(unichar *)value
{
    NSParameterAssert(value != NULL);
    unsigned scanLocation   = [self scanLocation];
    NSString *string        = [self string];
    if (scanLocation >= [string length])
        return NO;
    *value = [string characterAtIndex:scanLocation];
    return YES;
}

- (BOOL)scanCharacter:(unichar *)value
{
    unsigned scanLocation   = [self scanLocation];
    NSString *string        = [self string];
    if (scanLocation >= [string length])
        return NO;
    if (value != NULL)
        *value = [string characterAtIndex:scanLocation];
    [self setScanLocation:scanLocation + 1];
    return YES;
}

- (BOOL)scanC99Comment:(NSString **)value
{
    unsigned scanLocation = [self scanLocation];
    if ([self scanString:@"//" intoString:NULL])
    {
        [self scanUpToString:@"\n" intoString:value];
        [self scanString:@"\n" intoString:NULL];
        return YES;
    }

    // no comment found
    [self setScanLocation:scanLocation]; // reset
    return NO;
}

- (BOOL)scanCComment:(NSString **)value
{
    unsigned scanLocation = [self scanLocation];
    if ([self scanString:@"/*" intoString:NULL])
    {
        [self scanUpToString:@"*/" intoString:value];
        if ([self scanString:@"*/" intoString:NULL])
            return YES;
    }

    // no comment found
    [self setScanLocation:scanLocation]; // reset
    return NO;
}

- (BOOL)scanQuotedString:(NSString **)value
{
    unsigned scanLocation = [self scanLocation];
    NSString *tempString;
    if (![self scanString:@"\"" intoString:&tempString])
        return NO;

    NSCharacterSet *specials = [NSCharacterSet characterSetWithCharactersInString:@"\r\n\"\\"];
    NSMutableString *result = [NSMutableString stringWithString:tempString];

    while (![self isAtEnd])
    {
        if ([self scanUpToCharactersFromSet:specials intoString:&tempString])
            [result appendString:tempString];

        unichar character;
        if (![self scanCharacter:&character])
            goto bail;
        [result appendFormat:@"%C", character];

        switch (character)
        {
            case '\"': // found closing quote
                if (value != NULL) *value = [NSString stringWithString:result];
                return YES;
            case '\\': // found backslash, expect escaped next character
                if (![self scanCharacter:&character])
                    goto bail;
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
    return [self scanCharactersFromSet:[NSCharacterSet alphanumericCharacterSet] intoString:value];
}

- (BOOL)scanUpToMacroIntoString:(NSString **)value
{
    NSMutableString *scanned = [NSMutableString string];
    NSString *tempString;
    if ([self scanUpToString:[NSString stringWithFormat:@"%C", WO_LEFT_DELIMITER] intoString:&tempString])
        [scanned appendString:tempString];

    unsigned scanLocation = [self scanLocation];
    if ([self scanMacroIntoString:NULL])
        // macro found: must stop just before it
        [self setScanLocation:scanLocation];
    else
    {
        // no macro found: consume rest of string
        NSString *remainder = [self remainder];
        [scanned appendString:remainder];
        [self setScanLocation:[self scanLocation] + remainder.length];
    }

    if (value)
        *value = scanned;
    return (scanned.length > 0);
}

- (BOOL)scanMacroIntoString:(NSString **)value
{
    unsigned scanLocation       = [self scanLocation];
    NSString *leftDelimiter     = [NSString stringWithFormat:@"%C", WO_LEFT_DELIMITER];
    NSString *rightDelimiter    = [NSString stringWithFormat:@"%C", WO_RIGHT_DELIMITER];

    if ([self scanString:leftDelimiter intoString:NULL] &&
        [self scanUpToString:rightDelimiter intoString:value] &&
        [self scanString:rightDelimiter intoString:NULL])
        return YES;

    [self setScanLocation:scanLocation]; // reset
    return NO;
}

- (NSString *)remainder
{
    return [[self string] substringFromIndex:[self scanLocation]];
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
    while ([self scanLocation] <= originalLocation && ![self isAtEnd])
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

- (void)skipWhitespace
{
    NSCharacterSet *whitespace = [NSCharacterSet characterSetWithCharactersInString:@"\n\r\t "];
    [self scanCharactersFromSet:whitespace intoString:NULL];
}

- (void)complain:(NSString *)reason
{
    [NSException raise:NSGenericException format:@"%@ at %@", reason, [self scanLocationDescription]];
}

@end
