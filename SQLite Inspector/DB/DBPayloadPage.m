//
//  DBPayloadPage.m
//  SQLite Inspector
//
//  Created by R. Tony Goold on 07.07.2016.
//  Copyright © 2016 WP Technology Inc. All rights reserved.
//

#import "DBPayloadPage.h"

@interface DBPayloadPage () {
    NSUInteger mIndex;
}
@end

@implementation DBPayloadPage

- (instancetype)initWithIndex:(NSUInteger)index
                         data:(NSData *)data
                 reservedSize:(NSUInteger)reservedSize {
    NSAssert(index > 0U, @"Invalid page index");
    NSAssert(data.length >= reservedSize, @"Reserved size exceeds data length");
    self = [super init];
    if (self) {
        mIndex = index;
        _nextPageNumber = ntohl(*(uint32_t *)data.bytes);
        _payload = [data subdataWithRange:NSMakeRange(4, data.length - 4)];
    }
    return self;
}

- (NSUInteger)index {
    return mIndex;
}

- (DBPageType)pageType {
    return DBPageTypePayload;
}

- (BOOL)isCorrupt {
    // Payload (overflow) pages can only be interpreted in the context of the
    // cell whose overflow they contain. Docs are unclear whether nextPageNumber
    // should be monotonically increasing.
    return NO;
}

@end
