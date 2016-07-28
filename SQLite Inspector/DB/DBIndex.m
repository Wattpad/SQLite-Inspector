//
//  DBIndex.m
//  SQLite Inspector
//
//  Created by R. Tony Goold on 28.07.2016.
//  Copyright © 2016 WP Technology Inc. All rights reserved.
//

#import "DBIndex.h"

@implementation DBIndex

- (instancetype)initWithName:(NSString *)name
                       table:(NSString *)table
                    rootPage:(NSUInteger)rootPage
                         sql:(NSString *)sql {
    self = [super init];
    if (self) {
        _name = [name copy];
        _table = [table copy];
        _rootPage = rootPage;
        _sql = [sql copy];
    }
    return self;
}

@end
