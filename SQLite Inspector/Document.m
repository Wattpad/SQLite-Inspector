//
//  Document.m
//  SQLite Inspector
//
//  Created by R. Tony Goold on 07.07.2016.
//  Copyright © 2016 WP Technology Inc. All rights reserved.
//

#import "Document.h"

#import "DBAllPageEnumerator.h"
#import "DBBtreePage.h"
#import "DBReader.h"
#import "DBRecord.h"
#import "DBTable.h"
#import "DBTableEnumerator.h"
#import "VisualizationGenerator.h"
#import "VisualizationViewController.h"

@interface Document ()

@property (nonatomic, weak) NSWindowController *visualizationWindowController;

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
    content.representedObject = self.reader;
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
    return _reader != nil;
}

- (BOOL)isEntireFileLoaded {
    return NO;
}

- (IBAction)visualizeDocument:(id)sender {
    if (self.visualizationWindowController) {
        [self.visualizationWindowController showWindow:sender];
        return;
    }

    NSStoryboard *storyboard = [NSStoryboard storyboardWithName:@"Main" bundle:nil];
    NSWindowController *imageWindowController = [storyboard instantiateControllerWithIdentifier:@"Visualizer Window Controller"];
    NSViewController *imageController = imageWindowController.contentViewController;
    imageController.representedObject = [[VisualizationGenerator alloc] initWithReader:self.reader];

    [self addWindowController:imageWindowController];
    [imageWindowController showWindow:sender];
    self.visualizationWindowController = imageWindowController;
}

@end
