//
//  DBTable.h
//  SQLite Inspector
//
//  Created by R. Tony Goold on 14.07.2016.
//  Copyright © 2016 WP Technology Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DBTable : NSObject

@property (nonatomic, strong, readonly) NSString *name;
@property (nonatomic, readonly) NSUInteger rootPage;
@property (nonatomic, strong, readonly) NSString *sql;

- (instancetype)initWithName:(NSString *)name
                    rootPage:(NSUInteger)rootPage
                         sql:(NSString *)sql;

@end

NS_ASSUME_NONNULL_END
