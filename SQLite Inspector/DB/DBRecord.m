//
//  DBRecord.m
//  SQLite Inspector
//
//  Created by R. Tony Goold on 11.07.2016.
//  Copyright © 2016 WP Technology Inc. All rights reserved.
//

#import "DBRecord.h"

#import "DBVarint.h"

@interface DBRecord ()

@property (nonatomic, readonly) uint64_t headerLength;

- (uint64_t)offsetForColumnIndex:(NSUInteger)index;

@end

@implementation DBRecord

- (instancetype)initWithData:(NSData *)data {
    self = [super init];
    if (self) {
        _data = [data copy];
        _columns = [[NSMutableArray alloc] init];

        const char *bytes = self.data.bytes;
        size_t offset = 0U;
        size_t read;
        // First read the header length
        _headerLength = ReadVarint(&bytes[offset], &read);
        offset += read;
        // Now count the columns
        NSUInteger count = 0U;
        NSMutableArray *columns = [[NSMutableArray alloc] init];
        while (offset < _headerLength) {
            uint64_t columnType = ReadVarint(&bytes[offset], &read);
            [columns addObject:@(columnType)];
            offset += read;
            ++count;
        }
        _columns = [columns copy];
        NSCAssert(offset == _headerLength, @"Header length does not match specified length");
    }
    return self;
}

+ (NSUInteger)sizeForColumnType:(DBColumnType)type {
    switch (type) {
        case DBColumnTypeNull:
        case DBColumnTypeFalse:
        case DBColumnTypeTrue:
            return 0U;
        case DBColumnType8Bit:
            return 1U;
        case DBColumnType16Bit:
            return 2U;
        case DBColumnType24Bit:
            return 3U;
        case DBColumnType32Bit:
            return 4U;
        case DBColumnType48Bit:
            return 6U;
        case DBColumnType64Bit:
        case DBColumnTypeDouble:
            return 8U;
        default:
            // Check for reserved types
            NSAssert(type >= DBColumnTypeBlob, @"Unexpected reserved type found");
            return (type - ((type & 1) == 0 ? 12U : 13U)) / 2U;
    }
}

- (int64_t)integerAtIndex:(NSUInteger)index {
    const uint64_t offset = [self offsetForColumnIndex:index];
    const char *bytes = self.data.bytes;
    const DBColumnType type = self.columns[index].unsignedIntegerValue;
    NSAssert(type >= DBColumnType8Bit && type <= DBColumnType64Bit, @"Column is not an integer type");
    const NSUInteger size = [DBRecord sizeForColumnType:type];
    NSAssert(size <= 9U, @"Expected size no greater than 9 bytes, found %lu", (unsigned long)size);
    // Extract the bytes from big-endian to host order
    union {
        int64_t i;
        unsigned char b[8];
    } value = { .i = 0 };

    for (NSUInteger i = 0U; i < size; ++i) {
#if __DARWIN_BYTE_ORDER == __DARWIN_BIG_ENDIAN
        value.b[i] = bytes[i + offset];
#else
        value.b[7 - i] = bytes[i + offset];
#endif
    }
    // Sign-extend values less than 64 bits
    if (size < 8U) {
        value.i >>= (8U - size) * 8U;
    }
    return value.i;
}

- (double)doubleAtIndex:(NSUInteger)index {
    const uint64_t offset = [self offsetForColumnIndex:index];
    const char *bytes = self.data.bytes;
    const DBColumnType type = self.columns[index].unsignedIntegerValue;
    NSAssert(type == DBColumnTypeDouble, @"Column is not a floating point type");
    union {
        double d;
        unsigned char b[8];
    } value;
    for (NSUInteger i = 0U; i < 8U; ++i) {
#if __DARWIN_BYTE_ORDER == __DARWIN_BIG_ENDIAN
        value.b[i] = bytes[i + offset];
#else
        value.b[8 - i] = bytes[i + offset];
#endif
    }
    return value.d;
}

- (BOOL)boolAtIndex:(NSUInteger)index {
    const DBColumnType type = self.columns[index].unsignedIntegerValue;
    NSAssert(type == DBColumnTypeFalse || type == DBColumnTypeTrue, @"Column is not a boolean type");
    return type == DBColumnTypeFalse ? NO : YES;
}

- (NSData *)blobAtIndex:(NSUInteger)index {
    const uint64_t offset = [self offsetForColumnIndex:index];
    const char *bytes = self.data.bytes;
    const DBColumnType type = self.columns[index].unsignedIntegerValue;
    NSAssert(type >= DBColumnTypeBlob && (type & 1U) == 0U, @"Column is not a blob type");
    const NSUInteger size = [DBRecord sizeForColumnType:type];
    return [[NSData alloc] initWithBytes:&bytes[offset] length:size];
}

- (NSString *)stringAtIndex:(NSUInteger)index {
    const uint64_t offset = [self offsetForColumnIndex:index];
    const char *bytes = self.data.bytes;
    const DBColumnType type = self.columns[index].unsignedIntegerValue;
    NSAssert(type >= DBColumnTypeString && (type & 1U) == 1U, @"Column is not a string type");
    const NSUInteger size = [DBRecord sizeForColumnType:type];
    return [[NSString alloc] initWithBytes:&bytes[offset] length:size encoding:NSUTF8StringEncoding];
}

- (uint64_t)offsetForColumnIndex:(NSUInteger)index {
    NSAssert(index < self.columns.count, @"Index is not valid");
    uint64_t offset = 0U;
    for (NSUInteger i = 0; i < index; ++i) {
        NSNumber *value = self.columns[i];
        DBColumnType type = value.unsignedIntegerValue;
        offset += [DBRecord sizeForColumnType:type];
    }
    return offset + _headerLength;
}

@end
