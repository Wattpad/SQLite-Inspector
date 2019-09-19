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

NS_ASSUME_NONNULL_BEGIN

@protocol DBPage <NSObject>

@property (nonatomic, readonly) NSUInteger index;
@property (nonatomic, readonly) DBPageType pageType;
@property (nonatomic, readonly, getter=isCorrupt) BOOL corrupt;

+ (instancetype)alloc;

- (instancetype)initWithIndex:(NSUInteger)index
                         data:(NSData *)data
                 reservedSize:(NSUInteger)reservedSize;

@end

NS_ASSUME_NONNULL_END
