//
//  DBWalHeader.h
//  SQLite Inspector
//
//  Created by R. Tony Goold on 19.12.2016.
//  Copyright © 2016 WP Technology Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DBWalHeader : NSObject

@property (nonatomic, readonly) NSUInteger pageSize;
@property (nonatomic, readonly) NSUInteger sequenceNumber;
@property (nonatomic, readonly) NSUInteger salt1;
@property (nonatomic, readonly) NSUInteger salt2;
@property (nonatomic, readonly) NSUInteger checksum1;
@property (nonatomic, readonly) NSUInteger checksum2;

@property (nonatomic, readonly) BOOL isChecksumBigEndian;

/**
 *  Creates a new instance of a database WAL header from the given data. The
 *  data must contain at least 32 bytes.
 *
 *  @param data An on-disk representation of a database WAL header.
 *
 *  @return A new WAL header instance, or nil if insufficient bytes were given.
 */
- (nullable instancetype)initWithData:(NSData *)data;

@end

NS_ASSUME_NONNULL_END
