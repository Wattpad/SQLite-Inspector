//
//  DBWalFrameHeader.m
//  SQLite Inspector
//
//  Created by R. Tony Goold on 19.12.2016.
//  Copyright © 2016 WP Technology Inc. All rights reserved.
//

#import "DBWalFrameHeader.h"

#import <arpa/inet.h>

typedef struct __attribute((packed))__ {
    uint32_t pageNumber;
    uint32_t dbPageCount;
    uint32_t salt[2];
    uint32_t checksum[2];
} DBWalFrameHeader_t;

static DBWalFrameHeader_t HeaderFromData(const char *data) {
    DBWalFrameHeader_t header = *((DBWalFrameHeader_t *)data);
    header.pageNumber = ntohl(header.pageNumber);
    header.dbPageCount = ntohl(header.dbPageCount);
    header.salt[0] = ntohl(header.salt[0]);
    header.salt[1] = ntohl(header.salt[1]);
    header.checksum[0] = ntohl(header.checksum[0]);
    header.checksum[1] = ntohl(header.checksum[1]);
    return header;
}

@interface DBWalFrameHeader () {
    DBWalFrameHeader_t mHeader;
}
@end

@implementation DBWalFrameHeader

- (instancetype)initWithData:(NSData *)data {
    if (data.length < sizeof(DBWalFrameHeader_t)) {
        return nil;
    }

    self = [super init];
    if (self) {
        mHeader = HeaderFromData(data.bytes);
    }
    return self;
}

- (NSUInteger)pageNumber {
    return mHeader.pageNumber;
}

- (NSUInteger)dbPageCount {
    return mHeader.dbPageCount;
}

- (NSUInteger)salt1 {
    return mHeader.salt[0];
}

- (NSUInteger)salt2 {
    return mHeader.salt[1];
}

- (NSUInteger)checksum1 {
    return mHeader.checksum[0];
}

- (NSUInteger)checksum2 {
    return mHeader.checksum[1];
}

- (BOOL)isCommitFrame {
    return mHeader.dbPageCount != 0;
}

@end
