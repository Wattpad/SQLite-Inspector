//
//  DBBtreeCell.h
//  SQLite Inspector
//
//  Created by R. Tony Goold on 07.07.2016.
//  Copyright © 2016 WP Technology Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, DBBtreeCellType) {
    DBBtreeCellTypeTableLeaf,
    DBBtreeCellTypeTableInterior,
    DBBtreeCellTypeIndexLeaf,
    DBBtreeCellTypeIndexInterior
};

@interface DBBtreeCell : NSObject

@property (nonatomic, readonly) DBBtreeCellType cellType;
@property (nonatomic, readonly) NSUInteger leftChildPageNumber;
@property (nonatomic, readonly) NSUInteger rowId;
@property (nonatomic, readonly) NSData *payload;
@property (nonatomic, readonly) NSUInteger firstOverflowPageNumber;

- (instancetype)initWithCellType:(DBBtreeCellType)cellType
                           bytes:(const char *)bytes
                  maxUsableSpace:(NSUInteger)maxUsableSpace;

@end
