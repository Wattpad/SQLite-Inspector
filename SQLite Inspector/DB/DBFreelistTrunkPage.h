//
//  DBFreelistTrunkPage.h
//  SQLite Inspector
//
//  Created by R. Tony Goold on 07.07.2016.
//  Copyright © 2016 WP Technology Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "DBPage.h"

NS_ASSUME_NONNULL_BEGIN

@interface DBFreelistTrunkPage : NSObject <DBPage>

- (instancetype)initWithIndex:(NSUInteger)index
                         data:(NSData *)data
                 reservedSize:(NSUInteger)reservedSize;

/**
 *  The index of the next freelist page in the list, or zero if this is the
 *  last page.
 */
@property (nonatomic, readonly) NSUInteger nextFreelistPageIndex;

/**
 *  The page numbers of the freelist leaf pages this page points to.
 */
@property (nonatomic, readonly) NSIndexSet *leafPageNumbers;

@end

NS_ASSUME_NONNULL_END
