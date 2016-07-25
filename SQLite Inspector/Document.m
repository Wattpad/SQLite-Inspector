//
//  Document.m
//  SQLite Inspector
//
//  Created by R. Tony Goold on 07.07.2016.
//  Copyright © 2016 WP Technology Inc. All rights reserved.
//

#import "Document.h"

#import "DBBtreePage.h"
#import "DBReader.h"
#import "DBRecord.h"
#import "DBTable.h"
#import "DBTableEnumerator.h"

@interface Document ()

@end

@implementation Document

- (instancetype)init {
    self = [super init];
    if (self) {
        // Add your subclass-specific initialization here.
    }
    return self;
}

+ (BOOL)autosavesInPlace {
    return YES;
}

- (void)makeWindowControllers {
    // Override to return the Storyboard file name of the document.
    NSStoryboard *storyboard = [NSStoryboard storyboardWithName:@"Main" bundle:nil];
    NSWindowController *controller = [storyboard instantiateControllerWithIdentifier:@"Document Window Controller"];
    NSViewController *content = controller.contentViewController;
    content.representedObject = self;
    [self addWindowController:controller];
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
    // Insert code here to write your document to data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning nil.
    // You can also choose to override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
    [NSException raise:@"UnimplementedMethod" format:@"%@ is unimplemented", NSStringFromSelector(_cmd)];
    return nil;
}

- (BOOL)readFromURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError * _Nullable __autoreleasing *)outError {
    _reader = [[DBReader alloc] initWithFile:url.path];
    if (!_reader) {
        return NO;
    }

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        for (DBTable *table in _reader.tables) {
            NSLog(@"Table: %@", table.name);
        }
    });

    return YES;
}

- (BOOL)isEntireFileLoaded {
    return NO;
}

@end
