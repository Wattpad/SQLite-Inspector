//
//  DBBtreePage.m
//  SQLite Inspector
//
//  Created by R. Tony Goold on 07.07.2016.
//  Copyright © 2016 WP Technology Inc. All rights reserved.
//

#import "DBBtreePage.h"

#import "DBBtreeCell.h"

typedef struct __attribute((packed))__ {
    uint8_t treeType;
    uint16_t firstFreeblockOffset;
    uint16_t numCells;
    uint16_t cellContentOffset;
    uint8_t numFragmentedFreeBytes;
    uint32_t rightMostPointer; /* For interior b-trees only */
} DBBtreePageHeader_t;

/*
 * Structure of a DBBtreePage:
 *
 * +-----------------------------+
 * | DB Header (first page only) | 100 bytes
 * +-----------------------------+
 * | Btree Page Header           | 8 bytes (leaf), 12 bytes (interior)
 * +-----------------------------+
 * |                             |
 * | Cell Pointer Array          | 2n bytes, where n is the number of cells
 * |                             |
 * +-----------------------------+
 * |                             |
 * | Unallocated Space           | Variable
 * |                             |
 * +-----------------------------+
 * |                             |
 * | Cell Content Area           | Variable
 * |                             |
 * +-----------------------------+
 * | Reserved Region             | Usually 0 bytes
 * +-----------------------------+
 */

@interface DBBtreePage () {
    NSUInteger mIndex;
    NSData *mData;
    NSUInteger mUsableSize;
    DBBtreePageHeader_t mHeader;
}
@end

@implementation DBBtreePage

- (instancetype)initWithIndex:(NSUInteger)index
                         data:(NSData *)data
                 reservedSize:(NSUInteger)reservedSize {
    NSAssert(index > 0U, @"Invalid page index");
    self = [super init];
    if (self) {
        mIndex = index;
        mData = [data copy];
        mUsableSize = data.length - reservedSize;
        mHeader = *((DBBtreePageHeader_t *)[self headerPointer]);
        mHeader.firstFreeblockOffset = ntohs(mHeader.firstFreeblockOffset);
        mHeader.numCells = ntohs(mHeader.numCells);
        mHeader.cellContentOffset = ntohs(mHeader.cellContentOffset);
        if (self.isLeaf) {
            mHeader.rightMostPointer = 0U;
        } else {
            mHeader.rightMostPointer = ntohl(mHeader.rightMostPointer);
        }
    }
    return self;
}

- (NSUInteger)index {
    return mIndex;
}

- (DBPageType)pageType {
    return DBPageTypeBtree;
}

- (const void *)headerPointer {
    return &mData.bytes[mIndex == 1U ? 100U : 0U];
}

- (BOOL)isLeaf {
    // The leaf flag is contained in the 4th least significant bit
    return (mHeader.treeType & 0x08) != 0;
}

- (BOOL)isIndexTree {
    return (mHeader.treeType & 0x02) != 0;
}

- (BOOL)isZeroed {
    static const char kZeroes[4096];
    NSData *zeroed = [[NSData alloc] initWithBytesNoCopy:(void * _Nonnull)kZeroes
                                                  length:4096U
                                            freeWhenDone:NO];
    return [mData isEqualToData:zeroed];
}

- (BOOL)isCorrupt {
    switch (mHeader.treeType) {
        case 0x02:
        case 0x05:
        case 0x0A:
        case 0x0D:
            return NO;
        default:
            return YES;
    }
}

- (NSUInteger)numCells {
    return mHeader.numCells;
}

- (NSUInteger)rightMostPointer {
    return mHeader.rightMostPointer;
}

- (DBBtreeCell *)cellAtIndex:(NSUInteger)index {
    if (index >= self.numCells) {
        [NSException raise:NSRangeException format:@"Index %lu is not less than number of cells %lu",
         (unsigned long)index, (unsigned long)self.numCells];
    }
    const char * const bytes = mData.bytes;
    const uint16_t * const cellOffsets = (uint16_t *)([self headerPointer] + (self.isLeaf ? 8 : 12));
    const uint16_t offset = ntohs(cellOffsets[index]);
    DBBtreeCellType type;
    // The index flag is contained in the 2nd least significant bit
    if (self.isIndexTree) {
        type = self.isLeaf ? DBBtreeCellTypeIndexLeaf : DBBtreeCellTypeIndexInterior;
    } else {
        type = self.isLeaf ? DBBtreeCellTypeTableLeaf : DBBtreeCellTypeTableInterior;
    }
    return [[DBBtreeCell alloc] initWithCellType:type
                                           bytes:&bytes[offset]
                                  maxUsableSpace:mUsableSize];
}

@end
