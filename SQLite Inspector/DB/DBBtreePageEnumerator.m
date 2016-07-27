//
//  DBBtreePageEnumerator.m
//  SQLite Inspector
//
//  Created by R. Tony Goold on 27.07.2016.
//  Copyright © 2016 WP Technology Inc. All rights reserved.
//

#import "DBBtreePageEnumerator.h"

#import "DBBtreeCell.h"
#import "DBBtreePage.h"
#import "DBReader.h"

@interface DBBtreePageEnumerator ()

@property (nonatomic, strong, readonly) DBReader *reader;
@property (nonatomic, strong, readonly) DBBtreePage *rootPage;
@property (nonatomic) NSUInteger index;

@end

@implementation DBBtreePageEnumerator

- (instancetype)initWithReader:(DBReader *)reader
                      rootPage:(DBBtreePage *)rootPage {
    NSAssert(!rootPage.isLeaf, @"Use a DBBtreeCellEnumerator to enumerate leaf pages");
    self = [super init];
    if (self) {
        _reader = reader;
        _rootPage = rootPage;
    }
    return self;
}

- (id<DBPage>)nextObject {
    const NSUInteger numCells = self.rootPage.numCells;
    DBBtreePage *nextPage;
    if (self.index < numCells) {
        DBBtreeCell *cell = [self.rootPage cellAtIndex:self.index];
        nextPage = [self.reader btreePageAtIndex:cell.leftChildPageNumber];
        ++self.index;
    } else if (self.index == numCells) {
        nextPage = [self.reader btreePageAtIndex:self.rootPage.rightMostPointer];
        ++self.index;
    }
    return nextPage;
}

@end
