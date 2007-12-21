//
// NSScanner+WOAdditions.m
// wincent-strings-util
//
// Created by Wincent Colaiuta on 21 December 2007.
// Copyright 2007 Wincent Colaiuta.

// category header
#import "NSScanner+WOAdditions.h"

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

- (BOOL)scanComment:(NSString **)value
{
    unsigned scanLocation = [self scanLocation];

    // try single-line (Objective-C/C99) comment
    if ([self scanString:@"//" intoString:NULL])
    {
        [self scanUpToString:@"\n" intoString:value];
        [self scanString:@"\n" intoString:NULL];
        return YES;
    }

    // try multi-line (traditional C) comment
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
