//
// WOLocalizable.m
// wincent-strings-util
//
// Created by Wincent Colaiuta on 21 December 2007.
// Copyright 2007-2008 Wincent Colaiuta.

// class header
#import "WOLocalizable.h"

@implementation WOLocalizable

#pragma mark -
#pragma mark Creation

+ (WOLocalizable *)localizableWithKey:(NSString *)aKey value:(NSString *)aValue comments:(NSArray *)anArray
{
    return [[self alloc] initWithKey:aKey value:aValue comments:anArray];
}

- (id)initWithKey:(NSString *)aKey value:(NSString *)aValue comments:(NSArray *)anArray
{
    if ((self = [super init]))
    {
        self.key        = aKey;
        self.value      = aValue;
        self.comments   = anArray;
    }
    return self;
}

#pragma mark -
#pragma mark NSCopying protocol

- (id)copyWithZone:(NSZone *)zone
{
    return [[WOLocalizable allocWithZone:zone] initWithKey:self.key value:self.value comments:self.comments];
}

#pragma mark -
#pragma mark Properties

@synthesize key;
@synthesize value;
@synthesize comments;

@end
