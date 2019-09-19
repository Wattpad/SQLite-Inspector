//
//  DBUnrecognizedPage.h
//  SQLite Inspector
//
//  Created by R. Tony Goold on 07.07.2016.
//  Copyright © 2016 WP Technology Inc. All rights reserved.
//

#import "DBPage.h"

NS_ASSUME_NONNULL_BEGIN

@interface DBUnrecognizedPage : NSObject <DBPage>

- (instancetype)initWithIndex:(NSUInteger)index
                         data:(NSData *)data
                 reservedSize:(NSUInteger)reservedSize;

@end

NS_ASSUME_NONNULL_END
