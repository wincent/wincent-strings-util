//
// NSScanner+WOAdditions.h
// wincent-strings-util
//
// Created by Wincent Colaiuta on 21 December 2007.
// Copyright 2007 Wincent Colaiuta.

@interface NSScanner (WOAdditions)

- (BOOL)peekCharacter:(unichar *)value;
- (BOOL)scanCharacter:(unichar *)value;

//! Scan a single-line (Objective-C/C99) comment.
- (BOOL)scanC99Comment:(NSString **)value;

//! Scan a multi-line (traditional C) comment.
- (BOOL)scanCComment:(NSString **)value;

- (BOOL)scanQuotedString:(NSString **)value;
- (BOOL)scanUnquotedString:(NSString **)value;
- (NSString *)scanLocationDescription;
- (void)skipWhitespace;
- (void)complain:(NSString *)reason;

@end
