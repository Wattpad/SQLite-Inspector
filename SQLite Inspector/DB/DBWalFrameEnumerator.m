//
//  DBWalFrameEnumerator.m
//  SQLite Inspector
//
//  Created by R. Tony Goold on 20.12.2016.
//  Copyright © 2016 WP Technology Inc. All rights reserved.
//

#import "DBWalFrameEnumerator.h"

#import "DBWalFrameHeader.h"
#import "DBWalReader.h"

@interface DBWalFrameEnumerator () {
    DBWalReader *mReader;
    NSUInteger mOffset;
}
@end

@implementation DBWalFrameEnumerator

- (instancetype)initWithReader:(DBWalReader *)reader {
    self = [super init];
    if (self) {
        mReader = reader;
    }
    return self;
}

- (id)nextObject {
    if (!mReader) {
        return nil;
    }

    DBWalFrameHeader *frame = [mReader frameAtIndex:mOffset++];
    if (!frame) {
        // Invalidate the enumerator and release the reader once we hit the end
        mReader = nil;
    }
    return frame;
}

@end
