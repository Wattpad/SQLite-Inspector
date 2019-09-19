//
//  DBBtreePageEnumerator.h
//  SQLite Inspector
//
//  Created by R. Tony Goold on 27.07.2016.
//  Copyright © 2016 WP Technology Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DBBtreePage;
@class DBReader;

NS_ASSUME_NONNULL_BEGIN

/**
 *  Enumerates all the child pages of an internal B-tree page.
 *
 *  The enumeration is not a recursive enumeration.
 */
@interface DBBtreePageEnumerator : NSEnumerator<DBBtreePage *>

- (instancetype)initWithReader:(DBReader *)reader
                      rootPage:(DBBtreePage *)rootPage;

@end

NS_ASSUME_NONNULL_END
