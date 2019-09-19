//
//  DBWalReader.m
//  SQLite Inspector
//
//  Created by R. Tony Goold on 19.12.2016.
//  Copyright © 2016 WP Technology Inc. All rights reserved.
//

#import "DBWalReader.h"

#import "DBWalChecksum.h"
#import "DBWalFrameHeader.h"
#import "DBWalHeader.h"

@interface DBWalReader () {
    DBWalHeader *mHeader;
    NSFileHandle *mHandle;
}
@end

@implementation DBWalReader

@synthesize header = mHeader;

- (instancetype)initWithFile:(NSString *)path {
    NSFileHandle *handle = [NSFileHandle fileHandleForReadingAtPath:path];
    if (!handle) {
        NSLog(@"Unable to open WAL for reading");
        return nil;
    }

    NSData *data = [handle readDataOfLength:32];
    DBWalHeader *header = [[DBWalHeader alloc] initWithData:data];
    if (!header) {
        NSLog(@"Unable to read WAL header");
        return nil;
    }

    if (header.pageSize == 0) {
        NSLog(@"WAL header page size is zero");
        return nil;
    }

    const void *bytes = data.bytes;
    // Compute checksum on the first 24 bytes, i.e., 6 32-bit values
    uint32_t cs1 = 0;
    uint32_t cs2 = 0;
    DBWalChecksum(bytes, 6, header.isChecksumBigEndian, &cs1, &cs2);
    if (cs1 != header.checksum1 || cs2 != header.checksum2) {
        NSLog(@"WAL header checksum mismatch");
        return nil;
    }

    self = [super init];
    if (self) {
        mHeader = header;
        mHandle = handle;
    }
    return self;
}

- (NSArray<DBWalFrameHeader *> *)getFrames {
    NSMutableArray<DBWalFrameHeader *> *frames = [[NSMutableArray alloc] init];
    NSUInteger offset = 0;
    DBWalFrameHeader *frame;
    while ((frame = [self frameAtIndex:offset++]) != nil) {
        [frames addObject:frame];
    }
    return frames;
}

- (DBWalFrameHeader *)frameAtIndex:(NSUInteger)index {
    const NSUInteger offset = 32 + index * (24 + 1024);
    [mHandle seekToFileOffset:(unsigned long long)offset];
    return [[DBWalFrameHeader alloc] initWithData:[mHandle readDataOfLength:24]];
}

@end
