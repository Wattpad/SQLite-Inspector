//
//  DBWalFrameEnumerator.h
//  SQLite Inspector
//
//  Created by R. Tony Goold on 20.12.2016.
//  Copyright © 2016 WP Technology Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DBWalFrameHeader;
@class DBWalReader;

NS_ASSUME_NONNULL_BEGIN

@interface DBWalFrameEnumerator : NSEnumerator <DBWalFrameHeader *>

- (instancetype)initWithReader:(DBWalReader *)reader NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
