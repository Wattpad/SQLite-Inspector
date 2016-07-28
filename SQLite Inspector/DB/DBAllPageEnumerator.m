//
//  DBAllPageEnumerator.m
//  SQLite Inspector
//
//  Created by R. Tony Goold on 27.07.2016.
//  Copyright © 2016 WP Technology Inc. All rights reserved.
//

#import "DBAllPageEnumerator.h"

#import "DBBtreeCell.h"
#import "DBBtreeCellEnumerator.h"
#import "DBBtreePage.h"
#import "DBBtreePageEnumerator.h"
#import "DBFreelistEnumerator.h"
#import "DBLockBytePage.h"
#import "DBPayloadPageEnumerator.h"
#import "DBPointerMapPageEnumerator.h"
#import "DBReader.h"
#import "DBTableEnumerator.h"

@interface DBAllPageEnumerator ()

@property (nonatomic, strong, readonly) DBReader *reader;
@property (nonatomic, strong, readonly) NSMutableArray<NSEnumerator *> *enums;

@end

@implementation DBAllPageEnumerator

- (instancetype)initWithReader:(DBReader *)reader {
    self = [super init];
    if (self) {
        _reader = reader;
        _enums = [[NSMutableArray alloc] init];

        // Pre-populate the root page and all its table/index pages
        DBBtreePage *root = reader.rootBtreePage;
        NSMutableArray<DBBtreePage *> *roots = [[NSMutableArray alloc] init];
        [roots addObject:root];

        DBTableEnumerator *tableEnum = [[DBTableEnumerator alloc] initWithReader:reader
                                                                        rootPage:root];
        DBBtreeCell *cell;
        while ((cell = [tableEnum nextObject]) != nil) {
            NSArray *objects = [self.reader objectsForCell:cell];
            // Should be [ type, name, tbl_name, rootpage, sql ]
            NSNumber *pageNumber = objects[3];
            if (![pageNumber isEqualToNumber:@0]) {
                DBBtreePage *page = [reader btreePageAtIndex:pageNumber.unsignedIntegerValue];
                [roots addObject:page];
            }
        }
        [_enums addObject:roots.objectEnumerator];

        // Pre-populate the freelist page
        DBFreelistEnumerator *freeEnum = [[DBFreelistEnumerator alloc] initWithReader:reader];
        [_enums addObject:freeEnum];

        // Pre-populate the lock byte page
        DBLockBytePage *lockBytePage = reader.lockBytePage;
        if (lockBytePage != nil) {
            [_enums addObject:@[lockBytePage].objectEnumerator];
        }

        // Pre-populate the pointer map page
        DBPointerMapPageEnumerator *pointerEnum = [[DBPointerMapPageEnumerator alloc] initWithReader:reader];
        [_enums addObject:pointerEnum];
    }
    return self;
}

- (id<DBPage>)nextObject {
    id<DBPage> page;
    while (page == nil) {
        NSEnumerator<id<DBPage>> *enumerator = self.enums.lastObject;
        if (enumerator == nil) {
            break;
        }

        page = [enumerator nextObject];
        if (page == nil) {
            [self.enums removeLastObject];
            continue;
        }

        if (page.pageType == DBPageTypeBtree) {
            DBBtreePage *tree = (DBBtreePage *)page;
            if (tree.isLeaf) {
                DBBtreeCellEnumerator *cellEnum = [[DBBtreeCellEnumerator alloc] initWithReader:self.reader
                                                                                       rootPage:tree];
                DBBtreeCell *cell;
                while ((cell = [cellEnum nextObject]) != nil) {
                    if (cell.firstOverflowPageNumber != 0U) {
                        DBPayloadPageEnumerator *payloadEnum = [[DBPayloadPageEnumerator alloc] initWithReader:self.reader
                                                                                                          cell:cell];
                        [self.enums addObject:payloadEnum];
                    }
                }
            } else {
                DBBtreePageEnumerator *pageEnum = [[DBBtreePageEnumerator alloc] initWithReader:self.reader
                                                                                       rootPage:tree];
                [self.enums addObject:pageEnum];
            }
        }
    }
    return page;
}

@end
