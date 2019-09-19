//
//  DBPayloadPageEnumerator.h
//  SQLite Inspector
//
//  Created by R. Tony Goold on 27.07.2016.
//  Copyright © 2016 WP Technology Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DBBtreeCell;
@class DBPayloadPage;
@class DBReader;

NS_ASSUME_NONNULL_BEGIN

@interface DBPayloadPageEnumerator : NSEnumerator<DBPayloadPage *>

- (instancetype)initWithReader:(DBReader *)reader
                          cell:(DBBtreeCell *)cell;

@end

NS_ASSUME_NONNULL_END
