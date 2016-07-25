//
//  DBPage.h
//  SQLite Inspector
//
//  Created by R. Tony Goold on 07.07.2016.
//  Copyright © 2016 WP Technology Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, DBPageType) {
    DBPageTypeBtree,
    DBPageTypeFreelist,
    DBPageTypeLockByte,
    DBPageTypePayload,
    DBPageTypePointerMap,
    DBPageTypeUnknown
};

@protocol DBPage <NSObject>

@property (nonatomic, readonly) DBPageType pageType;

+ (instancetype)alloc;

- (instancetype)initWithIndex:(NSUInteger)index
                         data:(NSData *)data
                     pageSize:(NSUInteger)pageSize
                 reservedSize:(NSUInteger)reservedSize;

@end
