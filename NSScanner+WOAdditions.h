//
// NSScanner+WOAdditions.h
// wincent-strings-util
//
// Created by Wincent Colaiuta on 21 December 2007.
// Copyright 2007-2008 Wincent Colaiuta.

@interface NSScanner (WOAdditions)

- (BOOL)peekCharacter:(unichar *)value;
- (BOOL)scanCharacter:(unichar *)value;

//! Scan a single-line (Objective-C/C99) comment.
- (BOOL)scanC99Comment:(NSString **)value;

//! Scan a multi-line (traditional C) comment.
- (BOOL)scanCComment:(NSString **)value;

- (BOOL)scanQuotedString:(NSString **)value;
- (BOOL)scanUnquotedString:(NSString **)value;

//! Scans up to the first occurence of a macro.
//! Macros take the form <tt>&#x00ab;text&#x00bb;</tt> (where "text" is any text delimited by left and right double angle brackets).
- (BOOL)scanUpToMacroIntoString:(NSString **)value;

//! Scans past the macro at the current scan location.
//! Macros take the form <tt>&#x00ab;text&#x00bb;</tt> (where "text" is any text delimited by left and right double angle brackets).
//! Returns the text by reference in \p value; note that the leading and trailing double angle brackets are not included.
- (BOOL)scanMacroIntoString:(NSString **)value;

//! Return the unscanned portion of the string associated with the receiver.
//! If already at the end of the string returns the empty string.
- (NSString *)remainder;

- (NSString *)scanLocationDescription;
- (void)skipWhitespace;
- (void)complain:(NSString *)reason;

@end
