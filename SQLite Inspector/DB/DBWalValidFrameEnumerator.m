//
//  DBWalValidFrameEnumerator.m
//  SQLite Inspector
//
//  Created by R. Tony Goold on 20.12.2016.
//  Copyright © 2016 WP Technology Inc. All rights reserved.
//

#import "DBWalValidFrameEnumerator.h"

#import "DBWalFrameHeader.h"
#import "DBWalHeader.h"
#import "DBWalReader.h"

@interface DBWalValidFrameEnumerator () {
    uint32_t salt[2];
    uint32_t checksum[2];
}
@end

@implementation DBWalValidFrameEnumerator

- (instancetype)initWithReader:(DBWalReader *)reader {
    self = [super initWithReader:reader];
    if (self) {
        DBWalHeader *header = reader.header;
        salt[0] = (uint32_t)header.salt1;
        salt[1] = (uint32_t)header.salt2;
        checksum[0] = checksum[1] = 0;
    }
    return self;
}

@end
