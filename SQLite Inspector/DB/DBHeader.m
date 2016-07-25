//
//  DBHeader.m
//  SQLite Inspector
//
//  Created by R. Tony Goold on 07.07.2016.
//  Copyright © 2016 WP Technology Inc. All rights reserved.
//

#import "DBHeader.h"

#include <arpa/inet.h>

typedef struct __attribute((packed))__ {
    char signature[16]; /* "SQLite format 3\0" */
    uint16_t pageSize;
    uint8_t writeVersion; /* 1 for legacy, 2 for WAL */
    uint8_t readVersion; /* 1 for legacy, 2 for WAL */
    uint8_t pageReserveSize; /* Usually 0 */
    uint8_t maxEmbeddedPayloadFraction; /* Must be 64 */
    uint8_t minEmbeddedPayloadFraction; /* Must be 32 */
    uint8_t leafPayload; /* Must be 32 */
    uint32_t fileChangeCounter;
    uint32_t sizeInPages;
    uint32_t firstFreePageNumber;
    uint32_t numFreePages;
    uint32_t schemaCookie;
    uint32_t schemaFormat; /* 1, 2, 3, and 4 are supported */
    uint32_t defaultPageCacheSize;
    uint32_t largestRootPageNumber;
    uint32_t textEncoding; /* 1 for UTF-8, 2 for UTF-16LE, 3 for UTF-16BE */
    uint32_t userVersion;
    uint32_t incrementalVacuumEnabled; /* 0 for false, otherwise true */
    uint32_t applicationId;
    uint8_t reserved[20]; /* Reserved, must be all 0 */
    uint32_t versionValidFor; /* Which transaction updated the SQLite version */
    uint32_t sqliteVersion;
} DBHeader_t;

static DBHeader_t HeaderFromData(const char *data) {
    DBHeader_t header = *((DBHeader_t *)data);
    header.pageSize = ntohs(header.pageSize);
    header.fileChangeCounter = ntohl(header.fileChangeCounter);
    header.sizeInPages = ntohl(header.sizeInPages);
    header.firstFreePageNumber = ntohl(header.firstFreePageNumber);
    header.numFreePages = ntohl(header.numFreePages);
    header.schemaCookie = ntohl(header.schemaCookie);
    header.schemaFormat = ntohl(header.schemaFormat);
    header.defaultPageCacheSize = ntohl(header.defaultPageCacheSize);
    header.largestRootPageNumber = ntohl(header.largestRootPageNumber);
    header.textEncoding = ntohl(header.textEncoding);
    header.userVersion = ntohl(header.userVersion);
    header.incrementalVacuumEnabled = ntohl(header.incrementalVacuumEnabled);
    header.applicationId = ntohl(header.applicationId);
    header.versionValidFor = ntohl(header.versionValidFor);
    header.sqliteVersion = ntohl(header.sqliteVersion);
    return header;
}

@interface DBHeader () {
    DBHeader_t mHeader;
}
@end

@implementation DBHeader

- (instancetype)initWithData:(NSData *)data {
    if (data.length < sizeof(DBHeader_t)) {
        return nil;
    }
    self = [super init];
    if (self) {
        mHeader = HeaderFromData(data.bytes);
    }
    return self;
}

- (NSUInteger)pageSize {
    return mHeader.pageSize;
}

- (NSUInteger)pageReserveSize {
    return mHeader.pageReserveSize;
}

- (NSUInteger)sizeInPages {
    return mHeader.sizeInPages;
}

- (NSUInteger)numFreePages {
    return mHeader.numFreePages;
}

@end
