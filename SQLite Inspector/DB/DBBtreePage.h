//
//  DBBtreePage.h
//  SQLite Inspector
//
//  Created by R. Tony Goold on 07.07.2016.
//  Copyright © 2016 WP Technology Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "DBPage.h"

@class DBBtreeCell;

typedef NS_ENUM(NSUInteger, DBBtreeType) {
    DBBtreeTypeTable,
    DBBtreeTypeIndex,
    DBBtreeTypeUnknown
};

NS_ASSUME_NONNULL_BEGIN

@interface DBBtreePage : NSObject <DBPage>

- (instancetype)initWithIndex:(NSUInteger)index
                         data:(NSData *)data
                 reservedSize:(NSUInteger)reservedSize;

@property (nonatomic, readonly) DBBtreeType treeType;
@property (nonatomic, readonly) BOOL isLeaf;
@property (nonatomic, readonly) BOOL isIndexTree;
@property (nonatomic, readonly) NSUInteger numCells;
@property (nonatomic, readonly) NSUInteger rightMostPointer;
@property (nonatomic, readonly) BOOL isZeroed;
@property (nonatomic, readonly) BOOL isCorrupt;

- (DBBtreeCell *)cellAtIndex:(NSUInteger)index;

@end

NS_ASSUME_NONNULL_END
