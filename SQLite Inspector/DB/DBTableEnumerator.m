//
//  DBTableEnumerator.m
//  SQLite Inspector
//
//  Created by R. Tony Goold on 12.07.2016.
//  Copyright © 2016 WP Technology Inc. All rights reserved.
//

#import "DBTableEnumerator.h"

#import "DBBtreeCell.h"
#import "DBBtreePage.h"
#import "DBReader.h"

@interface DBTableEnumerator ()

@property (nonatomic, strong, readonly) DBReader *reader;
@property (nonatomic, strong, readonly) DBBtreePage *rootPage;
@property (nonatomic) NSUInteger index;
@property (nonatomic, strong, nullable) DBTableEnumerator *subEnum;

@end

@implementation DBTableEnumerator

- (instancetype)initWithReader:(DBReader *)reader
                      rootPage:(DBBtreePage *)rootPage {
    self = [super init];
    if (self) {
        _reader = reader;
        _rootPage = rootPage;
    }
    return self;
}

- (DBBtreeCell *)nextObject {
    if (self.subEnum != nil) {
        id next = [self.subEnum nextObject];
        if (next != nil) {
            return next;
        }
        self.subEnum = nil;
    }

    // TODO: Handle index pages (or create a DBIndexEnumerator class)

    const NSUInteger numCells = self.rootPage.numCells;
    if (self.index >= numCells) {
        // Interior pages have a right child pointer that is not included in the
        // number of cells.
        if (!self.rootPage.isLeaf && self.index == numCells) {
            self.subEnum = [[DBTableEnumerator alloc] initWithReader:self.reader
                                                            rootPage:[self.reader btreePageAtIndex:self.rootPage.rightMostPointer]];
            ++self.index;
            return [self nextObject];
        }
        return nil;
    }

    DBBtreeCell *cell = [self.rootPage cellAtIndex:self.index];
    ++self.index;
    if (self.rootPage.isLeaf) {
        return cell;
    } else {
        self.subEnum = [[DBTableEnumerator alloc] initWithReader:self.reader
                                                        rootPage:[self.reader btreePageAtIndex:cell.leftChildPageNumber]];
        return [self nextObject];
    }
}

@end
