//
//  DBBtreeCellEnumerator.h
//  SQLite Inspector
//
//  Created by R. Tony Goold on 27.07.2016.
//  Copyright © 2016 WP Technology Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DBBtreeCell;
@class DBBtreePage;
@class DBReader;

NS_ASSUME_NONNULL_BEGIN

/**
 *  Enumerates all the cells in a leaf B-tree page.
 */
@interface DBBtreeCellEnumerator : NSEnumerator<DBBtreeCell *>

- (instancetype)initWithReader:(DBReader *)reader
                      rootPage:(DBBtreePage *)rootPage;

@end

NS_ASSUME_NONNULL_END
