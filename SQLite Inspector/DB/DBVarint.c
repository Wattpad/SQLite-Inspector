//
//  DBVarint.c
//  SQLite Inspector
//
//  Created by R. Tony Goold on 11.07.2016.
//  Copyright © 2016 WP Technology Inc. All rights reserved.
//

#include "DBVarint.h"

uint64_t ReadVarint(const char *bytes, size_t *bytesRead) {
    size_t i = 0;
    // Count the leading n-1 bytes (maximum of 8)
    while (i < 8 && bytes[i] & 0x80) {
        ++i;
    }
    // Process the leading n-1 bytes
    uint64_t value = 0;
    for (size_t j = 0; j < i; ++j) {
        value <<= 7;
        value |= bytes[j] & 0x7F;
    }
    // Process the final byte (only include the 8th bit if using all 9 bytes)
    if (i == 8) {
        value <<= 8;
        value |= bytes[8];
    } else {
        value <<= 7;
        value |= bytes[i] & 0x7F;
    }
    if (bytesRead) {
        // Account for the final byte
        *bytesRead = i + 1;
    }
    return value;
}
