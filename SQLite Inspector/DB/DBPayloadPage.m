//
//  DBPayloadPage.m
//  SQLite Inspector
//
//  Created by R. Tony Goold on 07.07.2016.
//  Copyright © 2016 WP Technology Inc. All rights reserved.
//

#import "DBPayloadPage.h"

@implementation DBPayloadPage

- (instancetype)initWithIndex:(NSUInteger)index
                         data:(NSData *)data
                     pageSize:(NSUInteger)pageSize
                 reservedSize:(NSUInteger)reservedSize {
    self = [super init];
    if (self) {
        _nextPageNumber = ntohl(*(uint32_t *)data.bytes);
        _payload = [data subdataWithRange:NSMakeRange(4, data.length - 4)];
    }
    return self;
}

- (DBPageType)pageType {
    return DBPageTypePayload;
}

@end
