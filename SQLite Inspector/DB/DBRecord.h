//
//  DBRecord.h
//  SQLite Inspector
//
//  Created by R. Tony Goold on 11.07.2016.
//  Copyright © 2016 WP Technology Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, DBColumnType) {
    DBColumnTypeNull = 0,
    DBColumnType8Bit = 1,
    DBColumnType16Bit = 2,
    DBColumnType24Bit = 3,
    DBColumnType32Bit = 4,
    DBColumnType48Bit = 5,
    DBColumnType64Bit = 6,
    DBColumnTypeDouble = 7,
    DBColumnTypeFalse = 8,
    DBColumnTypeTrue = 9,
    DBColumnTypeBlob = 12,
    DBColumnTypeString = 13
};

NS_ASSUME_NONNULL_BEGIN

@interface DBRecord : NSObject

- (instancetype)initWithData:(NSData *)data;

@property (nonatomic, strong, readonly) NSData *data;
@property (nonatomic, strong, readonly) NSArray<NSNumber *> *columns;

+ (NSUInteger)sizeForColumnType:(DBColumnType)type;

- (int64_t)integerAtIndex:(NSUInteger)index;
- (double)doubleAtIndex:(NSUInteger)index;
- (BOOL)boolAtIndex:(NSUInteger)index;
- (NSData *)blobAtIndex:(NSUInteger)index;
- (NSString *)stringAtIndex:(NSUInteger)index;

@end

NS_ASSUME_NONNULL_END
