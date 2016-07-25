//
//  ViewController.m
//  SQLite Inspector
//
//  Created by R. Tony Goold on 07.07.2016.
//  Copyright © 2016 WP Technology Inc. All rights reserved.
//

#import "ViewController.h"

#import "DBBtreeCell.h"
#import "DBBtreePage.h"
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
@property (nonatomic, strong, nullable) NSNumber *pageNumber;
@property (nonatomic, strong, nullable) NSNumber *cellNumber;
@property (nonatomic, strong, nullable) NSNumber *columnNumber;

@end

@implementation DBEntry

- (instancetype)copyWithZone:(NSZone *)zone {
    DBEntry *entry = [[DBEntry allocWithZone:zone] init];
    entry.tableNumber = self.tableNumber;
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
           NumbersEqual(self.pageNumber, entry.pageNumber) &&
           NumbersEqual(self.cellNumber, entry.cellNumber) &&
           NumbersEqual(self.columnNumber, entry.columnNumber);
}

- (NSUInteger)hash {
    NSUInteger result = self.tableNumber.hash;
    result = (result * 17) ^ self.pageNumber.hash;
    result = (result * 17) ^ self.cellNumber.hash;
    result = (result * 17) & self.columnNumber.hash;
    return result;
}

@end

@interface ViewController ()

@property (nonatomic, copy) NSArray<DBTable *> *tables;
@property (nonatomic, copy) NSArray<DBEntry *> *tableEntries;
@property (nonatomic, strong, readonly) NSMutableDictionary<DBEntry *, NSArray<DBEntry *> *> *entries;

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
        DBBtreePage *page = [reader btreePageAtIndex:table.rootPage];
        const NSUInteger numCells = page.numCells;
        const BOOL hasRightChild = !page.isLeaf && page.rightMostPointer != 0U;
        NSMutableArray *children = [[NSMutableArray alloc] initWithCapacity:numCells + hasRightChild ? 1U : 0U];
        for (NSUInteger i = 0; i < numCells; ++i) {
            DBEntry *child = [[DBEntry alloc] init];
            child.pageNumber = @(table.rootPage);
            [children addObject:child];
        }
        self.entries[parent] = children;
    }];
    self.tableEntries = tableEntries;
    [self.outlineView reloadData];
}

- (Document *)document {
    return (Document *) self.representedObject;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    if (!item) {
        return (NSInteger)self.tables.count;
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

- (NSArray<DBEntry *> *)entriesForTable:(DBTable *)table entry:(DBEntry *)entry {
    NSArray<DBEntry *> *entries = self.entries[entry];
    if (!entries) {
        DBEntry *entry = [[DBEntry alloc] init];
        self.entries[entry] = entries = @[ entry ];
    }
    return entries;
}

- (NSArray<DBEntry *> *)entriesForEntry:(DBEntry *)entry {
    NSArray<DBEntry *> *entries = self.entries[entry];
    if (entries) {
        return entries;
    }

    if (entry.tableNumber) {
        DBTable *table = self.tables[entry.tableNumber.unsignedIntegerValue];
        entry.pageNumber = @(table.rootPage);
        return self.entries[entry] = @[ entry ];
    }

    DBReader *reader = self.document.reader;

    NSAssert(entry.pageNumber != nil, @"Non-table entry is missing its page number");
    DBBtreePage *page = [reader btreePageAtIndex:entry.pageNumber.unsignedIntegerValue];
    const NSUInteger numCells = page.numCells;
    if (!page.isLeaf) {
        NSAssert(entry.cellNumber == nil, @"Entry with non-leaf page should not specify a cell number");
        NSMutableArray<DBEntry *> *children = [[NSMutableArray alloc] initWithCapacity:numCells];
        for (NSUInteger i = 0; i < numCells; ++i) {
            DBEntry *child = [[DBEntry alloc] init];
            child.pageNumber = @([page cellAtIndex:i].leftChildPageNumber);
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
        return self.tableEntries[index];
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
    } else {
        return nil;
    }

    if (entry.tableNumber) {
        DBTable *table = self.tables[entry.tableNumber.unsignedIntegerValue];
        return isName ? table.name : @"Table";
    }

    NSAssert(entry.pageNumber != nil, @"Non-table entry is missing its page number");
    DBReader *reader = self.document.reader;
    DBBtreePage *page = [reader btreePageAtIndex:entry.pageNumber.unsignedIntegerValue];
    if (!entry.cellNumber) {
        if (isName) {
            return page.isIndexTree ? @"Index B-tree Page" : @"Table B-tree Page";
        } else {
            return page.isLeaf ? @"Leaf" : @"Internal";
        }
    }

    DBBtreeCell *cell = [page cellAtIndex:entry.cellNumber.unsignedIntegerValue];
    if (!entry.columnNumber) {
        return @"Cell";
    }

    id object = [reader objectsForCell:cell][entry.columnNumber.unsignedIntegerValue];
    return isName ? [object description] : [object className];
}

@end
