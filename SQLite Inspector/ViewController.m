//
//  ViewController.m
//  SQLite Inspector
//
//  Created by R. Tony Goold on 07.07.2016.
//  Copyright © 2016 WP Technology Inc. All rights reserved.
//

#import "ViewController.h"

#import "DBAllPageEnumerator.h"
#import "DBBtreeCell.h"
#import "DBBtreePage.h"
#import "DBIndex.h"
#import "DBReader.h"
#import "DBTable.h"
#import "Document.h"

static BOOL NumbersEqual(NSNumber *n1, NSNumber *n2) {
    if (!n1 || !n2) {
        return n1 == n2;
    }
    return [n1 isEqualToNumber:n2];
}

@interface DBEntry : NSObject <NSCopying>

@property (nonatomic, strong, nullable) NSNumber *tableNumber;
@property (nonatomic, strong, nullable) NSNumber *indexNumber;
@property (nonatomic, strong, nullable) NSNumber *pageNumber;
@property (nonatomic, strong, nullable) NSNumber *cellNumber;
@property (nonatomic, strong, nullable) NSNumber *columnNumber;

@end

@implementation DBEntry

- (instancetype)copyWithZone:(NSZone *)zone {
    DBEntry *entry = [[DBEntry allocWithZone:zone] init];
    entry.tableNumber = self.tableNumber;
    entry.indexNumber = self.indexNumber;
    entry.pageNumber = self.pageNumber;
    entry.cellNumber = self.cellNumber;
    entry.columnNumber = self.columnNumber;
    return entry;
}

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[DBEntry class]]) {
        return NO;
    }

    DBEntry *entry = (DBEntry *) object;
    return NumbersEqual(self.tableNumber, entry.tableNumber) &&
           NumbersEqual(self.indexNumber, entry.indexNumber) &&
           NumbersEqual(self.pageNumber, entry.pageNumber) &&
           NumbersEqual(self.cellNumber, entry.cellNumber) &&
           NumbersEqual(self.columnNumber, entry.columnNumber);
}

- (NSUInteger)hash {
    NSUInteger result = self.tableNumber.hash;
    result = (result * 17) ^ self.indexNumber.hash;
    result = (result * 17) ^ self.pageNumber.hash;
    result = (result * 17) ^ self.cellNumber.hash;
    result = (result * 17) & self.columnNumber.hash;
    return result;
}

@end

@interface ViewController ()

@property (nonatomic, copy) NSArray<DBTable *> *tables;
@property (nonatomic, copy) NSArray<DBIndex *> *indices;
@property (nonatomic, copy) NSArray<DBEntry *> *tableEntries;
@property (nonatomic, copy) NSArray<DBEntry *> *indexEntries;
@property (nonatomic, strong, readonly) NSMutableDictionary<DBEntry *, NSArray<DBEntry *> *> *entries;
@property (nonatomic, strong, nullable) NSImageView *imageView;

@end

@implementation ViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _entries = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        _entries = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
    if (![self isViewLoaded] || self.document == nil) {
        return;
    }

    DBReader *reader = self.document.reader;
    self.tables = reader.tables;
    NSMutableArray<DBEntry *> *tableEntries = [[NSMutableArray alloc] initWithCapacity:self.tables.count];
    [self.tables enumerateObjectsUsingBlock:^(DBTable * _Nonnull table, NSUInteger idx, BOOL * _Nonnull stop) {
        DBEntry *parent = [[DBEntry alloc] init];
        parent.tableNumber = @(idx);
        [tableEntries addObject:parent];

        DBEntry *child = [[DBEntry alloc] init];
        child.pageNumber = @(table.rootPage);
        self.entries[parent] = @[ child ];
    }];
    self.tableEntries = tableEntries;

    self.indices = reader.indices;
    NSMutableArray<DBEntry *> *indexEntries = [[NSMutableArray alloc] initWithCapacity:self.indices.count];
    [self.indices enumerateObjectsUsingBlock:^(DBIndex * _Nonnull index, NSUInteger idx, BOOL * _Nonnull stop) {
        DBEntry *parent = [[DBEntry alloc] init];
        parent.indexNumber = @(idx);
        [indexEntries addObject:parent];

        DBEntry *child = [[DBEntry alloc] init];
        child.pageNumber = @(index.rootPage);
        self.entries[parent] = @[ child ];
    }];
    self.indexEntries = indexEntries;

    [self.outlineView reloadData];
}

- (Document *)document {
    return (Document *) self.representedObject;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    if (!item) {
        return (NSInteger)(self.tables.count + self.indices.count);
    }

    if (![item isKindOfClass:[DBEntry class]]) {
        return 0;
    }

    DBEntry *entry = (DBEntry *) item;
    return [self entriesForEntry:entry].count;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    return [self outlineView:outlineView numberOfChildrenOfItem:item] > 0;
}

- (NSArray<DBEntry *> *)entriesForEntry:(DBEntry *)entry {
    NSArray<DBEntry *> *entries = self.entries[entry];
    if (entries) {
        return entries;
    }

    if (entry.tableNumber) {
        DBTable *table = self.tables[entry.tableNumber.unsignedIntegerValue];
        DBEntry *childEntry = [[DBEntry alloc] init];
        childEntry.pageNumber = @(table.rootPage);
        return self.entries[entry] = @[ childEntry ];
    } else if (entry.indexNumber) {
        DBIndex *index = self.indices[entry.indexNumber.unsignedIntegerValue];
        DBEntry *childEntry = [[DBEntry alloc] init];
        childEntry.pageNumber = @(index.rootPage);
        return self.entries[entry] = @[ childEntry ];
    }

    DBReader *reader = self.document.reader;

    NSAssert(entry.pageNumber != nil, @"Non-table entry is missing its page number");
    DBBtreePage *page = [reader btreePageAtIndex:entry.pageNumber.unsignedIntegerValue];
    const NSUInteger numCells = page.numCells;
    if (!page.isLeaf) {
        NSAssert(entry.cellNumber == nil, @"Entry with non-leaf page should not specify a cell number");
        NSMutableArray<DBEntry *> *children = [[NSMutableArray alloc] initWithCapacity:numCells + 1U];
        for (NSUInteger i = 0; i < numCells; ++i) {
            DBEntry *child = [[DBEntry alloc] init];
            DBBtreeCell *cell = [page cellAtIndex:i];
            child.pageNumber = @(cell.leftChildPageNumber);
            [children addObject:child];
        }
        if (page.rightMostPointer != 0U) {
            DBEntry *child = [[DBEntry alloc] init];
            child.pageNumber = @(page.rightMostPointer);
            [children addObject:child];
        }
        return self.entries[entry] = children;
    }

    if (!entry.cellNumber) {
        NSMutableArray<DBEntry *> *children = [[NSMutableArray alloc] initWithCapacity:numCells];
        for (NSUInteger i = 0; i < numCells; ++i) {
            DBEntry *child = [[DBEntry alloc] init];
            child.pageNumber = entry.pageNumber;
            child.cellNumber = @(i);
            [children addObject:child];
        }
        return self.entries[entry] = children;
    }

    const NSUInteger cellIndex = entry.cellNumber.unsignedIntegerValue;
    NSAssert(cellIndex < numCells, @"Cell number %lu is out of range 0..<%lu",
             (unsigned long)cellIndex, (unsigned long)numCells);
    DBBtreeCell *cell = [page cellAtIndex:cellIndex];
    if (!entry.columnNumber) {
        const NSUInteger numCols = [reader objectsForCell:cell].count;
        NSMutableArray<DBEntry *> *children = [[NSMutableArray alloc] init];
        for (NSUInteger i = 0; i < numCols; ++i) {
            DBEntry *child = [[DBEntry alloc] init];
            child.pageNumber = entry.pageNumber;
            child.cellNumber = entry.cellNumber;
            child.columnNumber = @(i);
            [children addObject:child];
        }
        return self.entries[entry] = children;
    }

    return self.entries[entry] = @[];
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
    if (!item) {
        const NSUInteger numTables = self.tableEntries.count;
        if (index < numTables) {
            return self.tableEntries[index];
        } else {
            return self.indexEntries[index - numTables];
        }
    }

    if (![item isKindOfClass:[DBEntry class]]) {
        return nil;
    }

    DBEntry *entry = (DBEntry *) item;
    NSArray<DBEntry *> *entries = [self entriesForEntry:entry];
    NSAssert(index < entries.count, @"Invalid index");
    return entries[index];
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
    if (![item isKindOfClass:[DBEntry class]]) {
        return nil;
    }
    DBEntry *entry = (DBEntry *) item;

    BOOL isName;
    if ([tableColumn.identifier isEqualToString:@"name"]) {
        isName = YES;
    } else if ([tableColumn.identifier isEqualToString:@"type"]) {
        isName = NO;
    } else if ([tableColumn.identifier isEqualToString:@"location"]) {
        if (entry.tableNumber != nil || entry.indexNumber != nil) {
            return @"";
        }
        NSString *location = [[NSString alloc] initWithFormat:@"Page %@ (0x%lx)",
                              entry.pageNumber, (unsigned long)self.document.reader.pageSize * (entry.pageNumber.unsignedIntegerValue - 1U)];
        if (entry.cellNumber != nil) {
            location = [location stringByAppendingFormat:@", Cell %@", entry.cellNumber];
        }
        if (entry.columnNumber != nil) {
            location = [location stringByAppendingFormat:@", Column %@", entry.columnNumber];
        }
        return location;
    } else {
        return nil;
    }

    if (entry.tableNumber != nil) {
        DBTable *table = self.tables[entry.tableNumber.unsignedIntegerValue];
        return isName ? table.name : @"Table";
    } else if (entry.indexNumber != nil) {
        DBIndex *index = self.indices[entry.indexNumber.unsignedIntegerValue];
        return isName ? index.name : [[NSString alloc] initWithFormat:@"Index on %@", index.table];
    }

    NSAssert(entry.pageNumber != nil, @"Non-table entry is missing its page number");
    DBReader *reader = self.document.reader;
    DBBtreePage *page = [reader btreePageAtIndex:entry.pageNumber.unsignedIntegerValue];
    if (!entry.cellNumber) {
        if (isName) {
            return page.isIndexTree ? @"Index B-tree Page" : @"Table B-tree Page";
        } else {
            if (page.isZeroed) { return @"Corrupt (Zeroed)"; }
            else if (page.isCorrupt) { return @"Corrupt (Other)"; }
            return page.isLeaf ? @"Leaf" : @"Internal";
        }
    }

    DBBtreeCell *cell = [page cellAtIndex:entry.cellNumber.unsignedIntegerValue];
    if (!entry.columnNumber) {
        return @"Cell";
    }

    id object = [reader objectsForCell:cell][entry.columnNumber.unsignedIntegerValue];
    if ([object isKindOfClass:[NSNull class]]) {
        return isName ? @"NULL" : @"Null";
    } else if ([object isKindOfClass:[NSNumber class]]) {
        return isName ? [object description] : @"Number";
    } else if ([object isKindOfClass:[NSString class]]) {
        return isName ? object : @"String";
    } else if ([object isKindOfClass:[NSData class]]) {
        return isName ? [NSString stringWithFormat:@"%lu bytes", (unsigned long)[object length]] : @"Blob";
    } else {
        NSAssert(NO, @"Unexpected data type");
        return isName ? [object description] : [object className];
    }
}

- (IBAction)generateZeroView:(id)sender {
    if (self.imageView) {
        [self.imageView removeFromSuperview];
        self.imageView = nil;
        return;
    }

    const NSUInteger numPages = self.document.reader.numPages;
    const NSUInteger blockSize = MAX(self.document.reader.pageSize >> 9U, 4U);
    const NSUInteger width = 1024 / blockSize;
    NSUInteger height = numPages / width;
    if (height * width < numPages) {
        ++height;
    }

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

    // Make async?
    DBAllPageEnumerator *allEnum = [[DBAllPageEnumerator alloc] initWithReader:self.document.reader];
    id<DBPage> page;
    while ((page = [allEnum nextObject]) != nil) {
        NSUInteger index = page.index - 1U;
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

    // Draw a border around the image
    memset(data, 0x00, bytesPerRow);
    memset(&data[bytesPerRow * (height * blockSize - 1)], 0x00, bytesPerRow);
    for (NSUInteger i = 1; i < height * blockSize - 1; ++i) {
        memset(&data[bytesPerRow * i], 0x00, 4);
        memset(&data[bytesPerRow * (i + 1) - 4], 0x00, 4);
    }

    [self.imageView removeFromSuperview];

    NSRect frame = NSMakeRect(0.0, 0.0, width * blockSize, height * blockSize);
    NSImage *image = [[NSImage alloc] initWithCGImage:bitmap.CGImage size:frame.size];
    self.imageView = [[NSImageView alloc] initWithFrame:self.view.bounds];
    self.imageView.layerContentsPlacement = NSViewLayerContentsPlacementScaleProportionallyToFit;
    self.imageView.image = image;
    [self.view addSubview:self.imageView];
}

@end
