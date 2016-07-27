//
//  DBPayloadPageEnumerator.m
//  SQLite Inspector
//
//  Created by R. Tony Goold on 27.07.2016.
//  Copyright © 2016 WP Technology Inc. All rights reserved.
//

#import "DBPayloadPageEnumerator.h"

#import "DBBtreeCell.h"
#import "DBPayloadPage.h"
#import "DBReader.h"

@interface DBPayloadPageEnumerator ()

@property (nonatomic, strong, readonly) DBReader *reader;
@property (nonatomic) NSUInteger nextPayloadPage;

@end

@implementation DBPayloadPageEnumerator

- (instancetype)initWithReader:(DBReader *)reader cell:(DBBtreeCell *)cell {
    self = [super init];
    if (self) {
        _reader = reader;
        _nextPayloadPage = cell.firstOverflowPageNumber;
    }
    return self;
}

- (DBPayloadPage *)nextObject {
    if (self.nextPayloadPage == 0U) {
        return nil;
    }

    DBPayloadPage *page = [self.reader payloadPageAtIndex:self.nextPayloadPage];
    self.nextPayloadPage = page.nextPageNumber;
    return page;
}

@end
