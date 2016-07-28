//
//  DBAllPageEnumerator.h
//  SQLite Inspector
//
//  Created by R. Tony Goold on 27.07.2016.
//  Copyright © 2016 WP Technology Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "DBPage.h"

@class DBReader;

@interface DBAllPageEnumerator : NSEnumerator <id<DBPage>>

- (instancetype)initWithReader:(DBReader *)reader;

@end
