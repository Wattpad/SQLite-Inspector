//
//  DBVarint.h
//  SQLite Inspector
//
//  Created by R. Tony Goold on 11.07.2016.
//  Copyright © 2016 WP Technology Inc. All rights reserved.
//

#ifndef DBVarint_h
#define DBVarint_h

#include <stdio.h>

uint64_t ReadVarint(const char *bytes, size_t *bytesRead);

#endif /* DBVarint_h */
