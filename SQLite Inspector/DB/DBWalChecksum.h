//
//  DBWalChecksum.h
//  SQLite Inspector
//
//  Created by R. Tony Goold on 20.12.2016.
//  Copyright © 2016 WP Technology Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

void DBWalChecksum(const uint32_t *xs,
                   uint32_t n,
                   boolean_t bigEndian,
                   uint32_t *cs1,
                   uint32_t *cs2);
