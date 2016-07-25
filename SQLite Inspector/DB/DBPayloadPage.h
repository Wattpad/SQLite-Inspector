//
//  DBPayloadPage.h
//  SQLite Inspector
//
//  Created by R. Tony Goold on 07.07.2016.
//  Copyright © 2016 WP Technology Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "DBPage.h"

NS_ASSUME_NONNULL_BEGIN

@interface DBPayloadPage : NSObject <DBPage>

- (instancetype)initWithIndex:(NSUInteger)index
                         data:(NSData *)data
                     pageSize:(NSUInteger)pageSize
                 reservedSize:(NSUInteger)reservedSize;

@property (nonatomic, readonly) NSUInteger nextPageNumber;
@property (nonatomic, readonly) NSData *payload;

@end

NS_ASSUME_NONNULL_END
