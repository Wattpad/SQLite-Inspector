//
//  DBWalReader.h
//  SQLite Inspector
//
//  Created by R. Tony Goold on 19.12.2016.
//  Copyright © 2016 WP Technology Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DBWalFrameHeader;
@class DBWalHeader;

NS_ASSUME_NONNULL_BEGIN

@interface DBWalReader : NSObject

@property (nonatomic, readonly) DBWalHeader *header;

- (nullable instancetype)initWithFile:(NSString *)path;

- (NSArray<DBWalFrameHeader *> *)getFrames;

- (nullable DBWalFrameHeader *)frameAtIndex:(NSUInteger)index;

@end

NS_ASSUME_NONNULL_END
