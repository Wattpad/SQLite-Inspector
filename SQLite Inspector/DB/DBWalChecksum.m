//
//  DBWalChecksum.m
//  SQLite Inspector
//
//  Created by R. Tony Goold on 20.12.2016.
//  Copyright © 2016 WP Technology Inc. All rights reserved.
//

#import "DBWalChecksum.h"

#include <libkern/OSByteOrder.h>

void DBWalChecksum(const uint32_t *xs,
                   uint32_t n,
                   boolean_t bigEndian,
                   uint32_t *cs1,
                   uint32_t *cs2) {
    if (cs1 == NULL || cs2 == NULL) {
        return;
    }

    if (n < 2 || (n & 1) != 0) {
        *cs1 = 0;
        *cs2 = 0;
        return;
    }

    uint32_t s1 = 0;
    uint32_t s2 = 0;
    if (bigEndian) {
        for (uint32_t i = 0; i < n - 1; i += 2) {
            s1 += OSReadBigInt32(&xs[i], 0) + s2;
            s2 += OSReadBigInt32(&xs[i], 4) + s1;
        }
    } else {
        for (uint32_t i = 0; i < n - 1; i += 2) {
            s1 += OSReadLittleInt32(&xs[i], 0) + s2;
            s2 += OSReadLittleInt32(&xs[i], 4) + s1;
        }
    }
    *cs1 = s1;
    *cs2 = s2;
}
