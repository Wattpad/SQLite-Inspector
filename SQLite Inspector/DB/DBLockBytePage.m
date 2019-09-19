//
//  DBLockBytePage.m
//  SQLite Inspector
//
//  Created by R. Tony Goold on 07.07.2016.
//  Copyright © 2016 WP Technology Inc. All rights reserved.
//

#import "DBLockBytePage.h"

@interface DBLockBytePage () {
    NSUInteger mIndex;
}
@end

@implementation DBLockBytePage

- (instancetype)initWithIndex:(NSUInteger)index
                         data:(NSData *)data
                 reservedSize:(NSUInteger)reservedSize {
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
    return DBPageTypeLockByte;
}

- (BOOL)isCorrupt {
    // The Lock-Byte page is reserved for use by VFS and does not contain SQLite data.
    return NO;
}

@end
