//
//  DBTableEnumerator.m
//  SQLite Inspector
//
//  Created by R. Tony Goold on 12.07.2016.
//  Copyright © 2016 WP Technology Inc. All rights reserved.
//

#import "DBTableEnumerator.h"

#import "DBBtreeCell.h"
#import "DBBtreeCellEnumerator.h"
#import "DBBtreePage.h"
#import "DBBtreePageEnumerator.h"
#import "DBReader.h"

@interface DBTableEnumerator ()

@property (nonatomic, strong, readonly) DBReader *reader;
@property (nonatomic, strong, readonly) NSMutableArray<DBBtreePageEnumerator *> *pageEnums;
@property (nonatomic, strong, nullable) DBBtreeCellEnumerator *cellEnum;

@end

@implementation DBTableEnumerator

- (instancetype)initWithReader:(DBReader *)reader
                      rootPage:(DBBtreePage *)rootPage {
    self = [super init];
    if (self) {
        _reader = reader;
        if (rootPage.isLeaf) {
            _pageEnums = [[NSMutableArray alloc] init];
            _cellEnum = [[DBBtreeCellEnumerator alloc] initWithReader:reader rootPage:rootPage];
        } else {
            DBBtreePageEnumerator *pageEnum = [[DBBtreePageEnumerator alloc] initWithReader:reader rootPage:rootPage];
            _pageEnums = [[NSMutableArray alloc] initWithObjects:pageEnum, nil];
        }
    }
    return self;
}

- (DBBtreeCell *)nextObject {
    if (self.cellEnum != nil) {
        DBBtreeCell *cell = [self.cellEnum nextObject];
        if (cell) {
            return cell;
        } else {
            self.cellEnum = nil;
        }
    }

    DBBtreePageEnumerator *pageEnum = self.pageEnums.lastObject;
    if (pageEnum == nil) {
        return nil;
    }

    DBBtreePage *page = [pageEnum nextObject];
    if (page == nil) {
        [self.pageEnums removeLastObject];
    } else if (page.isLeaf) {
        self.cellEnum = [[DBBtreeCellEnumerator alloc] initWithReader:self.reader rootPage:page];
    } else {
        pageEnum = [[DBBtreePageEnumerator alloc] initWithReader:self.reader rootPage:page];
        [self.pageEnums addObject:pageEnum];
    }

    return [self nextObject];
}

@end
