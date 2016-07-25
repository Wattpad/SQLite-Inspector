//
//  DBPointerMapPage.m
//  SQLite Inspector
//
//  Created by R. Tony Goold on 07.07.2016.
//  Copyright © 2016 WP Technology Inc. All rights reserved.
//

#import "DBPointerMapPage.h"

@implementation DBPointerMapPage

- (instancetype)initWithIndex:(NSUInteger)index
                         data:(NSData *)data
                     pageSize:(NSUInteger)pageSize
                 reservedSize:(NSUInteger)reservedSize {
    self = [super init];
    // Not parsing pointer map pages at this point
    return self;
}

- (DBPageType)pageType {
    return DBPageTypePointerMap;
}

@end
