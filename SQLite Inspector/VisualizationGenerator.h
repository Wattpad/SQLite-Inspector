//
//  VisualizationGenerator.h
//  SQLite Inspector
//
//  Created by R. Tony Goold on 03.08.2016.
//  Copyright © 2016 WP Technology Inc. All rights reserved.
//

#import <AppKit/AppKit.h>

@class DBReader;

NS_ASSUME_NONNULL_BEGIN

/**
 *  Generates database visualizations.
 */
@interface VisualizationGenerator : NSObject

/**
 *  Returns a new instance of a database visualization generator.
 *
 *  @param reader A database reader.
 *
 *  @return A new instance of a database visualization generator.
 */
- (instancetype)initWithReader:(DBReader *)reader;

/**
 *  Generates a visualization of the generator's database fitting a given
 *  dimension. The generator will attempt to fill as much of the space available
 *  as possible.
 *
 *  @param size The maximum dimensions of the image.
 *
 *  @return A visualization of the database.
 */
- (NSImage *)generateImageFittingSize:(CGSize)size;

@end

NS_ASSUME_NONNULL_END
