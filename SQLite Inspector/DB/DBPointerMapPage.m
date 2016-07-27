//
//  DBPointerMapPage.m
//  SQLite Inspector
//
//  Created by R. Tony Goold on 07.07.2016.
//  Copyright © 2016 WP Technology Inc. All rights reserved.
//

#import "DBPointerMapPage.h"

typedef struct __attribute((packed))__ {
    uint8_t type;
    uint32_t parent;
} DBPointerEntry;

@implementation DBPointerMap

- (instancetype)initWithType:(DBPageType)type
                        page:(NSUInteger)page
                      parent:(NSUInteger)parent {
    self = [super init];
    if (self) {
        _pageType = type;
        _pageNumber = page;
        _parentPageNumber = parent;
    }
    return self;
}

@end

@interface DBPointerMapPage () {
    NSUInteger mIndex;
    NSData *mData;
}
@end

@implementation DBPointerMapPage

- (instancetype)initWithIndex:(NSUInteger)index
                         data:(NSData *)data
                 reservedSize:(NSUInteger)reservedSize {
    // Not parsing pointer map pages at this point
    self = [super init];
    if (self) {
        mIndex = index;
        mData = data;
        _numPointers = (data.length - reservedSize) / 5U;
    }
    return self;
}

- (NSUInteger)index {
    return mIndex;
}

- (DBPageType)pageType {
    return DBPageTypePointerMap;
}

- (NSArray<DBPointerMap *> *)pointers {
    const NSUInteger numPointers = self.numPointers;
    NSMutableArray<DBPointerMap *> *pointers = [[NSMutableArray alloc] initWithCapacity:numPointers];
    const DBPointerEntry *entry = mData.bytes;
    for (NSUInteger i = 0; i < numPointers; ++i) {
        DBPageType type;
        switch (entry->type) {
            case 1: type = DBPageTypeBtree; break;
            case 2: type = DBPageTypeFreelist; break;
            case 3: type = DBPageTypePayload; break;
            case 4: type = DBPageTypePayload; break;
            case 5: type = DBPageTypeBtree; break;
            default: type = DBPageTypeUnknown;
        }
        DBPointerMap *map = [[DBPointerMap alloc] initWithType:type
                                                          page:self.index + i + 1U
                                                        parent:ntohl(entry->parent)];
        [pointers addObject:map];
    }
    return pointers;
}

@end
