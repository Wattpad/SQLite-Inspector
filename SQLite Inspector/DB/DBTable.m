//
//  DBTable.m
//  SQLite Inspector
//
//  Created by R. Tony Goold on 14.07.2016.
//  Copyright © 2016 WP Technology Inc. All rights reserved.
//

#import "DBTable.h"

@implementation DBTable

- (instancetype)initWithName:(NSString *)name
                    rootPage:(NSUInteger)rootPage
                         sql:(NSString *)sql {
    self = [super init];
    if (self) {
        _name = [name copy];
        _rootPage = rootPage;
        _sql = [sql copy];
    }
    return self;
}

@end
