//
//  DBPointerMapPageEnumerator.m
//  SQLite Inspector
//
//  Created by R. Tony Goold on 27.07.2016.
//  Copyright © 2016 WP Technology Inc. All rights reserved.
//

#import "DBPointerMapPageEnumerator.h"

#import "DBPointerMapPage.h"
#import "DBReader.h"

@interface DBPointerMapPageEnumerator ()

@property (nonatomic, strong, readonly) DBReader *reader;
@property (nonatomic, strong, nullable) DBPointerMapPage *nextPage;

@end

@implementation DBPointerMapPageEnumerator

- (instancetype)initWithReader:(DBReader *)reader {
    self = [super init];
    if (self) {
        _reader = reader;
        _nextPage = reader.firstPointerMapPage;
    }
    return self;
}

- (DBPointerMapPage *)nextObject {
    DBPointerMapPage *page = self.nextPage;
    if (page == nil) {
        return nil;
    }

    NSUInteger nextOffset = page.index + page.numPointers + 1U;
    if (nextOffset <= self.reader.numPages) {
        self.nextPage = [self.reader pointerMapPageAtIndex:nextOffset];
    } else {
        self.nextPage = nil;
    }
    return page;
}

@end
