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
    NSData *mData;
}
@end

@implementation DBFreelistTrunkPage

- (instancetype)initWithIndex:(NSUInteger)index
                         data:(NSData *)data
                 reservedSize:(NSUInteger)reservedSize {
    self = [super init];
    if (self) {
        mIndex = index;
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

- (NSUInteger)nextFreelistPageIndex {
    return ntohl(((DBFreelist_t *)mData.bytes)->nextPageIndex);
}

- (NSIndexSet *)leafPageNumbers {
    const DBFreelist_t *header = mData.bytes;
    const NSUInteger size = ntohl(header->numLeaves);
    NSMutableIndexSet *indices = [[NSMutableIndexSet alloc] init];
    for (NSUInteger i = 0; i < size; ++i) {
        [indices addIndex:header->leafPageIndices[i]];
    }
    return indices;
}

@end
