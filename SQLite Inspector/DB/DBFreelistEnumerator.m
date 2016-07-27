//
//  DBFreelistEnumerator.m
//  SQLite Inspector
//
//  Created by R. Tony Goold on 27.07.2016.
//  Copyright © 2016 WP Technology Inc. All rights reserved.
//

#import "DBFreelistEnumerator.h"

#import "DBFreelistLeafPage.h"
#import "DBFreelistTrunkPage.h"
#import "DBReader.h"

@interface DBFreelistEnumerator ()

@property (nonatomic, strong, readonly) DBReader *reader;
@property (nonatomic, copy) NSIndexSet *leafPageNumbers;
@property (nonatomic) NSUInteger nextLeaf;
@property (nonatomic) NSUInteger nextTrunk;

@end

@implementation DBFreelistEnumerator

- (instancetype)initWithReader:(DBReader *)reader rootPage:(DBFreelistTrunkPage *)rootPage {
    self = [super init];
    if (self) {
        _reader = reader;
        _leafPageNumbers = [rootPage.leafPageNumbers copy];
        _nextLeaf = _leafPageNumbers.firstIndex;
        _nextTrunk = rootPage.nextFreelistPageIndex;
    }
    return self;
}

- (id<DBPage>)nextObject {
    if (self.nextLeaf != NSNotFound) {
        NSUInteger pageNumber = self.nextLeaf;
        self.nextLeaf = [self.leafPageNumbers indexGreaterThanIndex:pageNumber];
        return [self.reader freelistLeafPageAtIndex:pageNumber];
    }

    DBFreelistTrunkPage *trunk = [self.reader freelistTrunkPageAtIndex:self.nextTrunk];
    if (trunk == nil) {
        return nil;
    }

    self.leafPageNumbers = trunk.leafPageNumbers;
    self.nextLeaf = self.leafPageNumbers.firstIndex;
    self.nextTrunk = trunk.nextFreelistPageIndex;
    return [self nextObject];
}

@end
