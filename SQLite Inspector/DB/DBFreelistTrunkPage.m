//
//  DBFreelistTrunkPage.m
//  SQLite Inspector
//
//  Created by R. Tony Goold on 07.07.2016.
//  Copyright © 2016 WP Technology Inc. All rights reserved.
//

#import "DBFreelistTrunkPage.h"

typedef struct {
    uint32_t nextPageIndex;
    uint32_t numLeaves;
    uint32_t leafPageIndices[];
} DBFreelist_t;

@interface DBFreelistTrunkPage () {
    NSUInteger mIndex;
    NSUInteger mUsableSize;
    NSData *mData;
}
@end

@implementation DBFreelistTrunkPage

- (instancetype)initWithIndex:(NSUInteger)index
                         data:(NSData *)data
                 reservedSize:(NSUInteger)reservedSize {
    NSAssert(index > 0U, @"Invalid page index");
    NSAssert(data.length >= reservedSize, @"Reserved size exceeds data length");
    self = [super init];
    if (self) {
        mIndex = index;
        mUsableSize = data.length - reservedSize;
        mData = [data copy];
    }
    return self;
}

- (NSUInteger)index {
    return mIndex;
}

- (DBPageType)pageType {
    return DBPageTypeFreelist;
}

- (BOOL)isCorrupt {
    const DBFreelist_t *header = mData.bytes;
    const NSUInteger size = ntohl(header->numLeaves) * 4U;
    if (size + 8U > mUsableSize) {
        NSLog(@"DBFreelistTrunkPage is corrupt because it is not big enough to contain its leaf list");
        return YES;
    }
    return NO;
}

- (NSUInteger)nextFreelistPageIndex {
    return ntohl(((DBFreelist_t *)mData.bytes)->nextPageIndex);
}

- (NSIndexSet *)leafPageNumbers {
    const DBFreelist_t *header = mData.bytes;
    const NSUInteger count = ntohl(header->numLeaves);
    NSMutableIndexSet *indices = [[NSMutableIndexSet alloc] init];
    for (NSUInteger i = 0; i < count; ++i) {
        [indices addIndex:ntohl(header->leafPageIndices[i])];
    }
    return indices;
}

@end
