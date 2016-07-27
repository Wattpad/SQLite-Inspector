//
//  DBFreelistLeafPage.m
//  SQLite Inspector
//
//  Created by R. Tony Goold on 27.07.2016.
//  Copyright © 2016 WP Technology Inc. All rights reserved.
//

#import "DBFreelistLeafPage.h"

@interface DBFreelistLeafPage () {
    NSUInteger mIndex;
}
@end

@implementation DBFreelistLeafPage

- (instancetype)initWithIndex:(NSUInteger)index
                         data:(NSData *)data
                 reservedSize:(NSUInteger)reservedSize {
    // Leaf pages contain arbitrary information
    self = [super init];
    if (self) {
        mIndex = index;
    }
    return self;
}

- (NSUInteger)index {
    return mIndex;
}

- (DBPageType)pageType {
    return DBPageTypeFreelist;
}

@end
