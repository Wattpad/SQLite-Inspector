//
//  Visualization.h
//  SQLite Inspector
//
//  Created by R. Tony Goold on 17.08.2016.
//  Copyright © 2016 WP Technology Inc. All rights reserved.
//

#import <AppKit/AppKit.h>

#import "DBPage.h"

NS_ASSUME_NONNULL_BEGIN

@interface Visualization : NSObject

@property (nonatomic, strong, readonly) NSImage *image;
@property (nonatomic, readonly) CGSize cellSize;

- (instancetype)initWithImage:(NSImage *)image
                     cellSize:(CGSize)cellSize
                    pageTypes:(NSArray<NSNumber *> *)pageTypes;

- (NSUInteger)pageIndexAtPoint:(CGPoint)point;

- (DBPageType)pageTypeAtIndex:(NSUInteger)index;

- (DBPageType)pageTypeAtPoint:(CGPoint)point;

@end

NS_ASSUME_NONNULL_END
