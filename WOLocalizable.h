//
// WOLocalizable.h
// wincent-strings-util
//
// Created by Wincent Colaiuta on 21 December 2007.
// Copyright 2007 Wincent Colaiuta.

//! Simple class that represents a localization entry in a strings file.
@interface WOLocalizable : NSObject <NSCopying> {

    NSString    *key;
    NSString    *value;
    NSArray     *comments;

}

#pragma mark -
#pragma mark Creation

+ (WOLocalizable *)localizableWithKey:(NSString *)aKey value:(NSString *)aValue comments:(NSArray *)anArray;
- (id)initWithKey:(NSString *)aKey value:(NSString *)aValue comments:(NSArray *)anArray;

#pragma mark -
#pragma mark Properties

@property(copy) NSString *key;
@property(copy) NSString *value;
@property(copy) NSArray *comments;

@end
