//
//  DBFreelistPage.m
//  SQLite Inspector
//
//  Created by R. Tony Goold on 07.07.2016.
//  Copyright © 2016 WP Technology Inc. All rights reserved.
//

#import "DBFreelistPage.h"

typedef struct {
    uint32_t nextPageIndex;
    uint32_t numLeaves;
    uint32_t leafPageIndices[];
} DBFreelist_t;

@interface DBFreelistPage () {
    NSData *mData;
}
@end

@implementation DBFreelistPage

- (instancetype)initWithIndex:(NSUInteger)index
                         data:(NSData *)data
                     pageSize:(NSUInteger)pageSize
                 reservedSize:(NSUInteger)reservedSize {
    self = [super init];
    if (self) {
        mData = [data copy];
    }
    return self;
}

- (DBPageType)pageType {
    return DBPageTypeFreelist;
}

- (NSUInteger)nextFreelistPageIndex {
    return ((DBFreelist_t *)mData.bytes)->nextPageIndex;
}

@end
