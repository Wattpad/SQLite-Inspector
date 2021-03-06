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
#import "DBFreelistLeafPage.h"
#import "DBFreelistTrunkPage.h"
#import "DBIndex.h"
#import "DBLockBytePage.h"
#import "DBPayloadPage.h"
#import "DBPointerMapPage.h"
#import "DBRecord.h"
#import "DBTable.h"
#import "DBTableEnumerator.h"
#import "DBUnrecognizedPage.h"
#import "DBWalReader.h"

// If the database is large enough to have a page at this offset, it is always
// the lock-byte page.
static const NSUInteger kLockBytePageOffset = 0x40000000;

@interface DBReader () {
    NSString *mPath;
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
        mPath = [path copy];
        mHeader = header;
        mHandle = input;
    }
    return self;
}

- (NSUInteger)numPages {
    // Legacy versions of SQLite do not maintain the sizeInPages field, and are
    // identified by also not updating the versionValidFor field.
    if (mHeader.sizeInPages != 0U && mHeader.fileChangeCounter == mHeader.versionValidFor) {
        return mHeader.sizeInPages;
    } else {
        [mHandle seekToEndOfFile];
        NSUInteger size = [mHandle offsetInFile];
        return size / mHeader.pageSize;
    }
}

- (NSUInteger)pageSize {
    return mHeader.pageSize;
}

- (NSArray<DBTable *> *)tables {
    DBBtreePage *root = self.rootBtreePage;
    if (root.corrupt) {
        NSLog(@"This isn't going to end well");
    }
    NSMutableArray<DBTable *> *tables = [[NSMutableArray alloc] init];
    [tables addObject:[[DBTable alloc] initWithName:@"sqlite_master"
                                           rootPage:1U
                                                sql:@"CREATE TABLE sqlite_master(type text, name text, tbl_name text, rootpage integer, sql text)"]];
    DBTableEnumerator *enumerator = [[DBTableEnumerator alloc] initWithReader:self rootPage:root];
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

- (NSArray<DBIndex *> *)indices {
    DBBtreePage *root = self.rootBtreePage;
    if (root.corrupt) {
        NSLog(@"This isn't going to end well");
    }
    NSMutableArray<DBIndex *> *indices = [[NSMutableArray alloc] init];
    DBTableEnumerator *enumerator = [[DBTableEnumerator alloc] initWithReader:self rootPage:root];
    for (DBBtreeCell *cell in enumerator) {
        // Should be [ type, name, tbl_name, rootpage, sql ]
        NSArray<id> *columns = [self objectsForCell:cell];
        NSAssert(columns.count == 5U, @"Expected 5 columns in table definition, found %lu", (unsigned long)columns.count);
        if (![columns[0] isEqualToString:@"index"]) {
            continue;
        }
        [indices addObject:[[DBIndex alloc] initWithName:columns[1]
                                                   table:columns[2]
                                                rootPage:[columns[3] unsignedIntegerValue]
                                                     sql:columns[4]]];
    }
    return indices;
}

- (DBBtreePage *)rootBtreePage {
    return [self pageAtIndex:1 class:[DBBtreePage class]];
}

- (NSUInteger)firstFreePageNumber {
    return mHeader.firstFreePageNumber;
}

- (DBPointerMapPage *)firstPointerMapPage {
    if (mHeader.largestRootPageNumber == 0U) {
        return nil;
    } else {
        return [self pageAtIndex:2U class:[DBPointerMapPage class]];
    }
}

- (NSUInteger)lockBytePageNumber {
    // The lock byte page offset is a multiple of 65536, the largest supported
    // page size, so this will always divide evenly.
    NSUInteger pageNumber = kLockBytePageOffset / self.pageSize + 1;
    return pageNumber <= self.numPages ? pageNumber : 0;
}

- (DBWalReader *)writeAheadLogReader {
    return [[DBWalReader alloc] initWithFile:[mPath stringByAppendingString:@"-wal"]];
}

- (DBBtreePage *)btreePageAtIndex:(NSUInteger)index {
    return [self pageAtIndex:index class:[DBBtreePage class]];
}

- (DBLockBytePage *)lockBytePage {
    return [self pageAtIndex:self.lockBytePageNumber class:[DBLockBytePage class]];
}

- (DBFreelistTrunkPage *)freelistTrunkPageAtIndex:(NSUInteger)index {
    return [self pageAtIndex:index class:[DBFreelistTrunkPage class]];
}

- (DBFreelistLeafPage *)freelistLeafPageAtIndex:(NSUInteger)index {
    return [self pageAtIndex:index class:[DBFreelistLeafPage class]];
}

- (DBPayloadPage *)payloadPageAtIndex:(NSUInteger)index {
    return [self pageAtIndex:index class:[DBPayloadPage class]];
}

- (DBPointerMapPage *)pointerMapPageAtIndex:(NSUInteger)index {
    return [self pageAtIndex:index class:[DBPointerMapPage class]];
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
                [values addObject:@NO];
                break;
            case DBColumnTypeTrue:
                [values addObject:@YES];
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

- (void)zeroedPagesWithCompletion:(void (^)(NSArray<NSNumber *> *))completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        static const char zeroes[4096];
        NSData *zeroed = [[NSData alloc] initWithBytesNoCopy:(void * _Nonnull)zeroes
                                                      length:4096
                                                freeWhenDone:NO];
        const NSUInteger numPages = self.numPages;
        NSMutableArray<NSNumber *> *pages = [[NSMutableArray alloc] init];
        [mHandle seekToFileOffset:0U];
        for (NSUInteger i = 0; i < numPages; ++i) {
            NSData *page = [mHandle readDataOfLength:4096];
            if ([page isEqualToData:zeroed]) {
                [pages addObject:@(i+1)];
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(pages);
        });
    });
}

@end
