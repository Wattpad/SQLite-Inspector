//
//  DBBtreeCellEnumerator.m
//  SQLite Inspector
//
//  Created by R. Tony Goold on 27.07.2016.
//  Copyright © 2016 WP Technology Inc. All rights reserved.
//

#import "DBBtreeCellEnumerator.h"

#import "DBBtreeCell.h"
#import "DBBtreePage.h"
#import "DBReader.h"

@interface DBBtreeCellEnumerator ()

@property (nonatomic, strong, readonly) DBReader *reader;
@property (nonatomic, strong, readonly) DBBtreePage *rootPage;
@property (nonatomic) NSUInteger index;

@end

@implementation DBBtreeCellEnumerator

- (instancetype)initWithReader:(DBReader *)reader
                      rootPage:(DBBtreePage *)rootPage {
    NSAssert(rootPage.isLeaf, @"Use a DBBtreePageEnumerator to enumerate internal pages");
    self = [super init];
    if (self) {
        _reader = reader;
        _rootPage = rootPage;
    }
    return self;
}

- (DBBtreeCell *)nextObject {
    if (self.index >= self.rootPage.numCells) {
        return nil;
    }
    return [self.rootPage cellAtIndex:self.index++];
}

@end
