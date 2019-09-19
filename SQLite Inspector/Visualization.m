//
//  Visualization.m
//  SQLite Inspector
//
//  Created by R. Tony Goold on 17.08.2016.
//  Copyright © 2016 WP Technology Inc. All rights reserved.
//

#import "Visualization.h"

@interface Visualization ()

@property (nonatomic, strong, readonly) NSArray<NSNumber *> *pageTypes;
@property (nonatomic, readonly) NSUInteger numColumns;

@end

@implementation Visualization

- (instancetype)initWithImage:(NSImage *)image
                     cellSize:(CGSize)cellSize
                    pageTypes:(NSArray<NSNumber *> *)pageTypes {
    self = [super init];
    if (self) {
        _image = image;
        _pageTypes = [pageTypes copy];
        _cellSize = cellSize;
        _numColumns = (NSUInteger)ceil(image.size.width / cellSize.width);
    }
    return self;
}

- (NSUInteger)pageIndexAtPoint:(CGPoint)point {
    const CGRect bounds = { CGPointZero, _image.size };
    if (!CGRectContainsPoint(bounds, point)) {
        return 0U;
    }
    const NSUInteger x = (NSUInteger)floor(point.x / _cellSize.width);
    const NSUInteger y = (NSUInteger)floor(point.y / _cellSize.height);
    return 1U + x + y * _numColumns;
}

- (DBPageType)pageTypeAtIndex:(NSUInteger)index {
    if (index == 0U || index > _pageTypes.count) {
        return DBPageTypeUnknown;
    }
    return _pageTypes[index - 1U].unsignedIntegerValue;
}

- (DBPageType)pageTypeAtPoint:(CGPoint)point {
    return [self pageTypeAtIndex:[self pageIndexAtPoint:point]];
}

@end
