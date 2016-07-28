//
//  DBReader.h
//  SQLite Inspector
//
//  Created by R. Tony Goold on 07.07.2016.
//  Copyright © 2016 WP Technology Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DBBtreeCell;
@class DBBtreePage;
@class DBFreelistLeafPage;
@class DBFreelistTrunkPage;
@class DBIndex;
@class DBLockBytePage;
@class DBPayloadPage;
@class DBPointerMapPage;
@class DBTable;

NS_ASSUME_NONNULL_BEGIN

/**
 *  A class capable of reading an SQLite 3 database file. The database is
 *  composed of multiple fixed size pages of different types. Page indices are
 *  1-based, and the index 0 is used as a sentinal value for "no page".
 */
@interface DBReader : NSObject

/**
 *  Creates a new database reader to read the database at a given path.
 *
 *  @param path The path of a database file.
 *
 *  @return A new database reader, or nil if the file does not appear to be a
 *          valid SQLite 3 database.
 */
- (nullable instancetype)initWithFile:(NSString *)path;

/**
 *  The total number of pages in the database, including free pages.
 */
@property (nonatomic, readonly) NSUInteger numPages;

/**
 *  The size of the database pages in bytes.
 */
@property (nonatomic, readonly) NSUInteger pageSize;

/**
 *  The root B-tree page. This corresponds to the sqlite_master table.
 */
@property (nonatomic, strong, readonly) DBBtreePage *rootBtreePage;

/**
 *  The page number of the first freelist page, or zero if there is none.
 */
@property (nonatomic, readonly) NSUInteger firstFreePageNumber;

/**
 *  The first pointer map page, or nil if there are no pointer map pages.
 */
@property (nonatomic, strong, readonly, nullable) DBPointerMapPage *firstPointerMapPage;

/**
 *  The page number of the lock byte page, or zero if there is none.
 */
@property (nonatomic, readonly) NSUInteger lockBytePageNumber;

/**
 *  All the tables in the database, excluding the sqlite_master table.
 */
@property (nonatomic, strong, readonly) NSArray<DBTable *> *tables;

/**
 *  All the indices in the database.
 */
@property (nonatomic, strong, readonly) NSArray<DBIndex *> *indices;

/**
 *  Returns the B-tree at the given page index. The behaviour is undefined if
 *  the page at that index is not a B-tree.
 *
 *  @param index A page index.
 *
 *  @return A B-tree page, or nil if the index is zero.
 */
- (nullable DBBtreePage *)btreePageAtIndex:(NSUInteger)index;

/**
 *  Returns the lock byte page, if it exists.
 *
 *  @return The lock byte page, or nil if it does not exist.
 */
- (nullable DBLockBytePage *)lockBytePage;

/**
 *  Returns the freelist trunk page at the given index. The behaviour is
 *  undefined if the page at that index is not a freelist trunk page.
 *
 *  @param index A page index.
 *
 *  @return A freelist trunk page, or nil if the index is zero.
 */
- (nullable DBFreelistTrunkPage *)freelistTrunkPageAtIndex:(NSUInteger)index;

/**
 *  Returns the freelist leaf page at the given index. The behaviour is
 *  undefined if the page at that index is not a freelist leaf page.
 *
 *  @param index A page index.
 *
 *  @return A freelist leaf page, or nil if the index is zero.
 */
- (nullable DBFreelistLeafPage *)freelistLeafPageAtIndex:(NSUInteger)index;

/**
 *  Returns the payload overflow at the given page index. The behaviour is
 *  undefined if the page at that index is not a payload overflow.
 *
 *  @param index A page index.
 *
 *  @return A payload overflow page, or nil if the index is zero.
 */
- (nullable DBPayloadPage *)payloadPageAtIndex:(NSUInteger)index;

/**
 *  Returns the pointer map page at the given index. The behaviour is undefined
 *  if the page at that index is not a pointer map.
 *
 *  @param index A apge index.
 *
 *  @return A pointer map page, or nil if the index is zero.
 */
- (nullable DBPointerMapPage *)pointerMapPageAtIndex:(NSUInteger)index;

/**
 *  Returns the complete payload for a B-tree cell.
 *
 *  @param cellIndex The index of the cell on the page.
 *  @param pageIndex The index of the page.
 *
 *  @return The cell's complete payload, or nil if pageIndex is zero.
 */
- (nullable NSData *)payloadForCellIndex:(NSUInteger)cellIndex
                               pageIndex:(NSUInteger)pageIndex;

/**
 *  Returns the complete payload for a B-tree cell.
 *
 *  @param cell The cell.
 *
 *  @return The cell's complete payload, or nil if the cell has no payload.
 */
- (nullable NSData *)payloadForCell:(DBBtreeCell *)cell;

/**
 *  Returns the objects represented by a B-tree cell's payload.
 *
 *  @param cell The cell.
 *
 *  @return The payload objects, or nil if the cell has no payload.
 */
- (nullable NSArray<id> *)objectsForCell:(DBBtreeCell *)cell;

/**
 *  Returns an array of zeroed pages with their one-based page numbers. This
 *  method executes asynchronously.
 *
 *  @param completion Callback for completion.
 */
- (void)zeroedPagesWithCompletion:(void (^ _Nonnull)(NSArray<NSNumber *> *))completion;

@end

NS_ASSUME_NONNULL_END
