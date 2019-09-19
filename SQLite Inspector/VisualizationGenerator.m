//
//  VisualizationGenerator.m
//  SQLite Inspector
//
//  Created by R. Tony Goold on 03.08.2016.
//  Copyright © 2016 WP Technology Inc. All rights reserved.
//

#import "VisualizationGenerator.h"

#import "DBAllPageEnumerator.h"
#import "DBBtreePage.h"
#import "DBReader.h"
#import "Visualization.h"

@interface VisualizationGenerator ()

@property (nonatomic, strong) DBReader *reader;

@end

@implementation VisualizationGenerator

- (instancetype)initWithReader:(DBReader *)reader {
    self = [super init];
    if (self) {
        _reader = reader;
    }
    return self;
}

- (Visualization *)visualizationFittingSize:(CGSize)size {
    NSAssert(size.width >= 1.0, @"Width must be at least 1.0");
    NSAssert(size.height >= 1.0, @"Height must be at least 1.0");

    const NSUInteger numPages = self.reader.numPages;
    NSAssert(numPages > 0U, @"Cannot visualize an empty database");

    const NSUInteger width = ceil(sqrt(numPages * size.width / size.height));
    NSUInteger height = numPages / width;
    if (width * height < numPages) {
        ++height;
    }
    const NSUInteger blockSize = floor(size.width / width);

    NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL
                                                                       pixelsWide:width * blockSize
                                                                       pixelsHigh:height * blockSize
                                                                    bitsPerSample:8
                                                                  samplesPerPixel:3
                                                                         hasAlpha:NO
                                                                         isPlanar:NO
                                                                   colorSpaceName:NSCalibratedRGBColorSpace
                                                                     bitmapFormat:0
                                                                      bytesPerRow:0
                                                                     bitsPerPixel:32];
    NSAssert(bitmap != nil, @"Unable to create bitmap representation");
    unsigned char *data = bitmap.bitmapData;
    memset(data, 0xFF, bitmap.bytesPerRow * height * blockSize);
    const NSUInteger bytesPerRow = bitmap.bytesPerRow;
    typedef unsigned char Px;
    void (^ColorPage)(NSUInteger, Px, Px, Px) = ^(NSUInteger page, Px r, Px g, Px b) {
        const NSUInteger baseRow = page / width;
        const NSUInteger baseCol = page - (baseRow * width);
        const NSUInteger baseOffset = blockSize * (baseRow * bytesPerRow + baseCol * 4);
        for (NSUInteger row = 0; row < blockSize; ++row) {
            for (NSUInteger col = 0; col < blockSize; ++col) {
                const NSUInteger offset = baseOffset + row * bytesPerRow + col * 4;
                data[offset + 0] = r;
                data[offset + 1] = g;
                data[offset + 2] = b;
                data[offset + 3] = 0xFF;
            }
        }

    };

    DBAllPageEnumerator *allEnum = [[DBAllPageEnumerator alloc] initWithReader:self.reader];
    id<DBPage> page;
    NSMutableArray<NSNumber *> *pageTypes = [[NSMutableArray alloc] initWithCapacity:numPages];
    for (NSUInteger i = 0U; i < numPages; ++i) {
        [pageTypes addObject:@(DBPageTypeUnknown)];
    }
    while ((page = [allEnum nextObject]) != nil) {
        NSUInteger index = page.index - 1U;
        pageTypes[index] = @(page.pageType);
        switch (page.pageType) {
            case DBPageTypeBtree: {
                DBBtreePage *tree = (DBBtreePage *)page;
                if (tree.isZeroed) {
                    ColorPage(index, 0xFF, 0x00, 0x00);
                } else if (tree.isIndexTree) {
                    ColorPage(index, 0x00, 0xFF, 0x00);
                } else {
                    ColorPage(index, 0x00, 0x7F, 0x00);
                }
                break;
            }
            case DBPageTypePayload:
                ColorPage(index, 0x00, 0x00, 0xFF);
                break;
            case DBPageTypeFreelist:
                ColorPage(index, 0x7F, 0x7F, 0x7F);
                break;
            case DBPageTypePointerMap:
                ColorPage(index, 0xFF, 0x00, 0xFF);
                break;
            case DBPageTypeLockByte:
                ColorPage(index, 0x00, 0xFF, 0xFF);
                break;
            default:
                ColorPage(index, 0x7F, 0x00, 0x00);
        }
    }

    // Indicate past the end of file with black
    const NSUInteger drawnPages = width * height;
    for (NSUInteger page = numPages + 1; page < drawnPages; ++page) {
        ColorPage(page, 0x00, 0x00, 0x00);
    }

    NSRect frame = NSMakeRect(0.0, 0.0, width * blockSize, height * blockSize);
    NSImage *image = [[NSImage alloc] initWithCGImage:bitmap.CGImage size:frame.size];
    return [[Visualization alloc] initWithImage:image
                                       cellSize:CGSizeMake(blockSize, blockSize)
                                      pageTypes:pageTypes];
}

@end
