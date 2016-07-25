//
//  DBUnrecognizedPage.m
//  SQLite Inspector
//
//  Created by R. Tony Goold on 07.07.2016.
//  Copyright © 2016 WP Technology Inc. All rights reserved.
//

#import "DBUnrecognizedPage.h"

@implementation DBUnrecognizedPage

- (instancetype)initWithIndex:(NSUInteger)index
                         data:(NSData *)data
                     pageSize:(NSUInteger)pageSize
                 reservedSize:(NSUInteger)reservedSize {
    return [super init];
}

- (DBPageType)pageType {
    return DBPageTypeUnknown;
}

@end
