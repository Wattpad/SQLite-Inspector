//
//  DBReader.m
//  SQLite Inspector
//
//  Created by R. Tony Goold on 07.07.2016.
//  Copyright © 2016 WP Technology Inc. All rights reserved.
//

#import "DBReader.h"

#import "DBHeader.h"

#import "DBBtreeCell.h"
#import "DBBtreePage.h"
#import "DBFreelistPage.h"
#import "DBLockBytePage.h"
#import "DBPayloadPage.h"
#import "DBPointerMapPage.h"
#import "DBRecord.h"
#import "DBTable.h"
#import "DBTableEnumerator.h"
#import "DBUnrecognizedPage.h"

// If the database is large enough to have a page at this offset, it is always
// the lock-byte page.
static const NSUInteger kLockBytePageOffset = 0x40000000;

@interface DBReader () {
    DBHeader *mHeader;
    NSFileHandle *mHandle;
}

- (nullable id<DBPage>)pageAtIndex:(NSUInteger)index class:(Class<DBPage>)class;

@end

@implementation DBReader

- (nullable instancetype)initWithFile:(NSString *)path {
    NSFileHandle *input = [NSFileHandle fileHandleForReadingAtPath:path];
    if (!input) {
        return nil;
    }
    DBHeader *header = [[DBHeader alloc] initWithData:[input readDataOfLength:100U]];
    if (!header) {
        return nil;
    }
    self = [super init];
    if (self) {
        mHeader = header;
        mHandle = input;
    }
    return self;
}

- (NSUInteger)numPages {
    return mHeader.sizeInPages;
}

- (NSArray<DBTable *> *)tables {
    NSMutableArray<DBTable *> *tables = [[NSMutableArray alloc] init];
    DBTableEnumerator *enumerator = [[DBTableEnumerator alloc] initWithReader:self
                                                                     rootPage:self.rootBtreePage];
    for (DBBtreeCell *cell in enumerator) {
        // Should be [ type, name, tbl_name, rootpage, sql ]
        NSArray<id> *columns = [self objectsForCell:cell];
        NSAssert(columns.count == 5U, @"Expected 5 columns in table definition, found %lu", (unsigned long)columns.count);
        if (![columns[0] isEqualToString:@"table"]) {
            continue;
        }
        [tables addObject:[[DBTable alloc] initWithName:columns[1]
                                               rootPage:[columns[3] unsignedIntegerValue]
                                                    sql:columns[4]]];
    }
    return tables;
}

- (DBBtreePage *)rootBtreePage {
    return [self pageAtIndex:1 class:[DBBtreePage class]];
}

- (DBBtreePage *)btreePageAtIndex:(NSUInteger)index {
    return [self pageAtIndex:index class:[DBBtreePage class]];
}

- (DBPayloadPage *)payloadPageAtIndex:(NSUInteger)index {
    return [self pageAtIndex:index class:[DBPayloadPage class]];
}

- (id<DBPage>)pageAtIndex:(NSUInteger)index class:(Class<DBPage>)class {
    if (index == 0U) {
        return nil;
    } else if (index > self.numPages) {
        [NSException raise:NSInvalidArgumentException format:@"Page index %lu exceeds maximum index %lu",
         (unsigned long)index, (unsigned long)self.numPages];
    }

    const NSUInteger kPageSize = mHeader.pageSize;
    const NSUInteger offset = (index - 1U) * kPageSize;
    [mHandle seekToFileOffset:offset];
    NSData *data = [mHandle readDataOfLength:kPageSize];
    if (data.length != kPageSize) {
        return nil;
    }
    // Special case for this offset
    if (offset == kLockBytePageOffset) {
        class = [DBLockBytePage class];
    }
    return [[class alloc] initWithIndex:index
                                   data:data
                               pageSize:kPageSize
                           reservedSize:mHeader.pageReserveSize];
}

- (nullable NSData *)payloadForCellIndex:(NSUInteger)cellIndex
                               pageIndex:(NSUInteger)pageIndex {
    DBBtreePage *page = [self btreePageAtIndex:pageIndex];
    if (!page) {
        return nil;
    }

    return [self payloadForCell:[page cellAtIndex:cellIndex]];
}

- (nullable NSData *)payloadForCell:(DBBtreeCell *)cell {
    NSData *data = cell.payload;
    NSUInteger overflowPage = cell.firstOverflowPageNumber;
    if (overflowPage == 0U) {
        return data;
    }
    NSMutableData *buffer = [data mutableCopy];
    while (overflowPage != 0U) {
        DBPayloadPage *page = [self payloadPageAtIndex:overflowPage];
        [buffer appendData:page.payload];
        overflowPage = page.nextPageNumber;
    }
    return buffer;
}

- (nullable NSArray<id> *)objectsForCell:(DBBtreeCell *)cell {
    NSData *data = [self payloadForCell:cell];
    if (!data || data.length == 0U) {
        return nil;
    }

    DBRecord *record = [[DBRecord alloc] initWithData:data];
    NSArray<NSNumber *> *columns = record.columns;
    NSMutableArray *values = [[NSMutableArray alloc] initWithCapacity:columns.count];
    for (NSUInteger j = 0; j < columns.count; ++j) {
        DBColumnType type = columns[j].unsignedIntegerValue;
        switch (type) {
            case DBColumnTypeNull:
                [values addObject:[NSNull null]];
                break;
            case DBColumnType8Bit:
            case DBColumnType16Bit:
            case DBColumnType24Bit:
            case DBColumnType32Bit:
            case DBColumnType48Bit:
            case DBColumnType64Bit:
                [values addObject:@([record integerAtIndex:j])];
                break;
            case DBColumnTypeDouble:
                [values addObject:@([record doubleAtIndex:j])];
                break;
            case DBColumnTypeFalse:
                [values addObject:@"FALSE"];
                break;
            case DBColumnTypeTrue:
                [values addObject:@"TRUE"];
                break;
            default:
                if (type >= DBColumnTypeBlob && (type & 1) == 0) {
                    [values addObject:[record blobAtIndex:j]];
                } else if (type >= DBColumnTypeString && (type & 1) == 1) {
                    [values addObject:[record stringAtIndex:j]];
                } else {
                    NSAssert(type >= DBColumnTypeBlob, @"Type is a reserved type");
                }
                break;
        }
    }
    return values;
}

@end
