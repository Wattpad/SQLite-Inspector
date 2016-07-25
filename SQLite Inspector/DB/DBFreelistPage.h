//
//  DBFreelistPage.h
//  SQLite Inspector
//
//  Created by R. Tony Goold on 07.07.2016.
//  Copyright © 2016 WP Technology Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "DBPage.h"

NS_ASSUME_NONNULL_BEGIN

@interface DBFreelistPage : NSObject <DBPage>

- (instancetype)initWithIndex:(NSUInteger)index
                         data:(NSData *)data
                     pageSize:(NSUInteger)pageSize
                 reservedSize:(NSUInteger)reservedSize;

/**
 *  The index of the next freelist page in the list, or zero if this is the
 *  last page.
 */
@property (nonatomic, readonly) NSUInteger nextFreelistPageIndex;

@end

NS_ASSUME_NONNULL_END
