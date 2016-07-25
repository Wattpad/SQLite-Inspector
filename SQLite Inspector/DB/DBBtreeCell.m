//
//  DBBtreeCell.m
//  SQLite Inspector
//
//  Created by R. Tony Goold on 07.07.2016.
//  Copyright © 2016 WP Technology Inc. All rights reserved.
//

#import "DBBtreeCell.h"

#import "DBVarint.h"

/*
 * Structure of a Cell:
 *
 * +-----------------------------+
 * | Left child page number      | 32-bit integer (interior table only)
 * +-----------------------------+
 * | Payload size in bytes       | Varint (all but interior table)
 * +-----------------------------+
 * | Integer key (rowid)         | Varint (table only)
 * +-----------------------------+
 * | Payload                     | Byte array (all but interior table)
 * +-----------------------------+
 * | First overflow page number  | 32-bit integer (all but interior table)
 * +-----------------------------+
 */

@implementation DBBtreeCell

- (instancetype)initWithCellType:(DBBtreeCellType)cellType
                           bytes:(const char *)bytes
                  maxUsableSpace:(NSUInteger)maxUsableSpace {
    self = [super init];
    if (self) {
        _cellType = cellType;
        size_t i = 0;
        uint64_t payloadSize = 0;
        // Read either left child page number or the payload size
        if (cellType == DBBtreeCellTypeTableInterior) {
            _leftChildPageNumber = ntohl(*(uint32_t *)&bytes[i]);
            i += 4;
        } else {
            size_t read;
            payloadSize = ReadVarint(&bytes[i], &read);
            i += read;
        }
        // Read the rowId
        if (cellType == DBBtreeCellTypeTableLeaf || cellType == DBBtreeCellTypeTableInterior) {
            size_t read;
            _rowId = ReadVarint(&bytes[i], &read);
            i += read;
        }
        // Read the payload and overflow page number
        if (cellType == DBBtreeCellTypeTableInterior) {
            _payload = [[NSData alloc] init];
            _firstOverflowPageNumber = 0U;
        } else {
            // How much is stored in each cell is a non-trivial calculation
            size_t maxSize = maxUsableSpace - 12;
            if (cellType != DBBtreeCellTypeTableLeaf) {
                maxSize = (maxSize * 64) / 255;
            }
            maxSize -= 23;
            const size_t minSize = (maxUsableSpace - 12) * 32 / 255 - 23;
            const size_t k = minSize + ((payloadSize - minSize) % (maxUsableSpace - 4));
            size_t cellPayloadSize;
            if (payloadSize < maxSize) {
                cellPayloadSize = payloadSize;
            } else if (k <= maxSize) {
                cellPayloadSize = k;
            } else {
                cellPayloadSize = minSize;
            }
            _payload = [[NSData alloc] initWithBytes:&bytes[i] length:cellPayloadSize];
            i += cellPayloadSize;

            if (cellPayloadSize == payloadSize) {
                _firstOverflowPageNumber = 0U;
            } else {
                _firstOverflowPageNumber = ntohl(*(uint32_t *)&bytes[i]);
            }
        }
    }
    return self;
}

@end
