//
//  DBPointerMapPage.h
//  SQLite Inspector
//
//  Created by R. Tony Goold on 07.07.2016.
//  Copyright © 2016 WP Technology Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "DBPage.h"

NS_ASSUME_NONNULL_BEGIN

@interface DBPointerMap : NSObject

@property (nonatomic, readonly) DBPageType pageType;
@property (nonatomic, readonly) NSUInteger pageNumber;
@property (nonatomic, readonly) NSUInteger parentPageNumber;

- (instancetype)initWithType:(DBPageType)type
                        page:(NSUInteger)page
                      parent:(NSUInteger)parent;

@end

@interface DBPointerMapPage : NSObject <DBPage>

- (instancetype)initWithIndex:(NSUInteger)index
                         data:(NSData *)data
                 reservedSize:(NSUInteger)reservedSize;

@property (nonatomic, readonly) NSUInteger numPointers;
@property (nonatomic, readonly) NSArray<DBPointerMap *> *pointers;

@end

NS_ASSUME_NONNULL_END
