//
//  DBFreelistEnumerator.h
//  SQLite Inspector
//
//  Created by R. Tony Goold on 27.07.2016.
//  Copyright © 2016 WP Technology Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "DBPage.h"

@class DBFreelistTrunkPage;
@class DBReader;

NS_ASSUME_NONNULL_BEGIN

/**
 *  Enumerates all the freelist pages (trunk and leaf) in the database.
 */
@interface DBFreelistEnumerator : NSEnumerator<id<DBPage>>

- (instancetype)initWithReader:(DBReader *)reader;

@end

NS_ASSUME_NONNULL_END
