//
//  DBWalHeader.m
//  SQLite Inspector
//
//  Created by R. Tony Goold on 19.12.2016.
//  Copyright © 2016 WP Technology Inc. All rights reserved.
//

#import "DBWalHeader.h"

#include <arpa/inet.h>

#import "DBWalChecksum.h"

typedef struct __attribute((packed))__ {
    uint32_t signature; /* 0x377f0682 or 0x377f0683 */
    uint32_t fileFormat; /* Usually 3007000 */
    uint32_t pageSize;
    uint32_t sequenceNumber;
    uint32_t salt[2];
    uint32_t checksum[2];
} DBWalHeader_t;

static DBWalHeader_t HeaderFromData(const char *data) {
    DBWalHeader_t header = *((DBWalHeader_t *)data);
    header.signature = ntohl(header.signature);
    header.fileFormat = ntohl(header.fileFormat);
    header.pageSize = ntohl(header.pageSize);
    header.sequenceNumber = ntohl(header.sequenceNumber);
    header.salt[0] = ntohl(header.salt[0]);
    header.salt[1] = ntohl(header.salt[1]);
    header.checksum[0] = ntohl(header.checksum[0]);
    header.checksum[1] = ntohl(header.checksum[1]);
    return header;
}

@interface DBWalHeader () {
    DBWalHeader_t mHeader;
}
@end

@implementation DBWalHeader

- (instancetype)initWithData:(NSData *)data {
    if (data.length < sizeof(DBWalHeader_t)) {
        return nil;
    }

    self = [super init];
    if (self) {
        mHeader = HeaderFromData(data.bytes);
        if (mHeader.signature != 0x377f0682 && mHeader.signature != 0x377f0863) {
            return nil;
        }
        if (mHeader.fileFormat != 3007000) {
            return nil;
        }

        // Calculate the checksum
        uint32_t s1, s2;
        DBWalChecksum((const uint32_t *)&mHeader, 6, mHeader.signature == 0x377f0682, &s1, &s2);
        if (s1 != mHeader.checksum[0] || s2 != mHeader.checksum[1]) {
            NSLog(@"WAL file header has invalid checksum");
            return nil;
        }
    }
    return self;
}

- (NSUInteger)pageSize {
    return mHeader.pageSize;
}

- (NSUInteger)sequenceNumber {
    return mHeader.sequenceNumber;
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

- (BOOL)isChecksumBigEndian {
    return mHeader.signature == 0x377f0683;
}

@end
