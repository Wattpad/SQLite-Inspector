//
//  DBWalFrameHeader.h
//  SQLite Inspector
//
//  Created by R. Tony Goold on 19.12.2016.
//  Copyright © 2016 WP Technology Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DBWalFrameHeader : NSObject

@property (nonatomic, readonly) NSUInteger pageNumber;
@property (nonatomic, readonly) NSUInteger dbPageCount;
@property (nonatomic, readonly) NSUInteger salt1;
@property (nonatomic, readonly) NSUInteger salt2;
@property (nonatomic, readonly) NSUInteger checksum1;
@property (nonatomic, readonly) NSUInteger checksum2;

@property (nonatomic, readonly) BOOL isCommitFrame;

- (nullable instancetype)initWithData:(NSData *)data;

@end

NS_ASSUME_NONNULL_END
