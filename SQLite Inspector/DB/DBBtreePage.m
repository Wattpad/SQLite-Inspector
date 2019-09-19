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
    NSAssert(data.length >= reservedSize, @"Reserved size exceeds data length");
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

- (const uint16_t *)cellPointerArray {
    return (uint16_t *)([self headerPointer] + (self.isLeaf ? 8 : 12));
}

- (BOOL)isLeaf {
    // The leaf flag is contained in the 4th least significant bit
    return (mHeader.treeType & 0x08) != 0;
}

- (BOOL)isIndexTree {
    // If the tree is an index type, then the 2nd least significant bit is set,
    // otherwise it is a table type and the 1st and 3rd least significant bits are set
    return (mHeader.treeType & 0x02) != 0;
}

- (BOOL)isZeroed {
    // This assumes pages are 4096 bytes in size, instead it should really adjust the
    // page size to match
    static const char kZeroes[4096];
    NSData *zeroed = [[NSData alloc] initWithBytesNoCopy:(void * _Nonnull)kZeroes
                                                  length:4096U
                                            freeWhenDone:NO];
    return [mData isEqualToData:zeroed];
}

- (BOOL)isCorrupt {
    // Check tree type value is valid
    switch (mHeader.treeType) {
        case 0x02:
        case 0x05:
        case 0x0A:
        case 0x0D:
            break;
        default:
            NSLog(@"DBBtreePage is corrupt because of unexpected tree type %x", mHeader.treeType);
            return YES;
    }

    // Check free/used space counts are valid and accurate
    NSUInteger numBytes = mUsableSize;
    const NSUInteger dbHeaderSize = (mIndex == 1U) ? 100U : 0U;
    if (numBytes < dbHeaderSize) {
        NSLog(@"DBBtreePage is corrupt because it is not big enough to contain the DB header");
        return YES;
    }
    numBytes -= dbHeaderSize;

    const NSUInteger pageHeaderSize = (self.isLeaf) ? 8U : 12U;
    if (numBytes < pageHeaderSize) {
        NSLog(@"DBBtreePage is corrupt because it is not big enough to contain its page header");
        return YES;
    }
    numBytes -= pageHeaderSize;

    const NSUInteger cellPointerSize = self.numCells * 2U;
    if (numBytes < cellPointerSize) {
        NSLog(@"DBBtreePage is corrupt because it is not big enough to contain its cell pointer array");
        return YES;
    }
    numBytes -= cellPointerSize;

    // Special case for empty 64K pages with no reserved space, 0 means 65536
    const NSUInteger cellContentOffset = (mHeader.cellContentOffset == 0U) ? 65536U : mHeader.cellContentOffset;
    if (cellContentOffset < pageHeaderSize + cellPointerSize) {
        NSLog(@"DBBtreePage is corrupt because the cell content region overlaps the header area");
        return YES;
    }
    const NSUInteger unallocatedSize = cellContentOffset - (pageHeaderSize + cellPointerSize);
    if (numBytes < unallocatedSize) {
        NSLog(@"DBBtreePage is corrupt because the cell content region starts beyond the usable space");
        return YES;
    }
    numBytes -= unallocatedSize;

    // Make sure the content cells are all at valid offsets
    const uint16_t * const cellPointers = [self cellPointerArray];
    const NSUInteger cellContentEndOffset = cellContentOffset + numBytes;
    for (NSUInteger i = 0; i < self.numCells; ++i) {
        const uint16_t cellPointer = ntohs(cellPointers[i]);
        if (cellPointer < cellContentOffset || cellPointer >= cellContentEndOffset) {
            NSLog(@"DBBtreePage is corrupt because a cell pointer points outside the content region");
            return YES;
        }
    }

    if (numBytes < mHeader.numFragmentedFreeBytes) {
        NSLog(@"DBBtreePage is corrupt because it is not big enough to contain its fragmented free bytes");
        return YES;
    }
    numBytes -= mHeader.numFragmentedFreeBytes;

    // Use a conservative estimate to determine the minimum number of bytes for content cells
    NSUInteger minCellSize;
    if (self.isIndexTree) {
        minCellSize = self.isLeaf ? 2 : 6;
    } else {
        minCellSize = self.isLeaf ? 3 : 5;
    }
    if (numBytes < minCellSize * self.numCells) {
        NSLog(@"DBBtreePage is corrupt because it is not big enough to contain its cell content");
        return YES;
    }
    // numBytes -= minCellSize * self.numCells;

    return NO;
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
    const uint16_t * const cellOffsets = [self cellPointerArray];
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
