//
//  DBHeader.h
//  SQLite Inspector
//
//  Created by R. Tony Goold on 07.07.2016.
//  Copyright © 2016 WP Technology Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DBHeader : NSObject

/**
 *  Creates a new instance of a database header from the given data. The data
 *  must contain at least 100 bytes.
 *
 *  @param data An on-disk representation of a database header.
 *
 *  @return A new header instance, or nil if insufficient bytes were given.
 */
- (nullable instancetype)initWithData:(NSData *)data;

@property (nonatomic, readonly) NSUInteger pageSize;
@property (nonatomic, readonly) NSUInteger pageReserveSize;
@property (nonatomic, readonly) NSUInteger fileChangeCounter;
@property (nonatomic, readonly) NSUInteger sizeInPages;
@property (nonatomic, readonly) NSUInteger firstFreePageNumber;
@property (nonatomic, readonly) NSUInteger numFreePages;
@property (nonatomic, readonly) NSUInteger largestRootPageNumber;
@property (nonatomic, readonly) NSUInteger versionValidFor;

@end

NS_ASSUME_NONNULL_END
