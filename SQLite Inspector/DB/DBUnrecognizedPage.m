//
//  DBUnrecognizedPage.m
//  SQLite Inspector
//
//  Created by R. Tony Goold on 07.07.2016.
//  Copyright © 2016 WP Technology Inc. All rights reserved.
//

#import "DBUnrecognizedPage.h"

@interface DBUnrecognizedPage () {
    NSUInteger mIndex;
}
@end

@implementation DBUnrecognizedPage

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
    return DBPageTypeUnknown;
}

- (BOOL)isCorrupt {
    NSLog(@"DBUnrecognizedPage is always an indication of corruption");
    return YES;
}

@end
