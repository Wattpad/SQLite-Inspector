//
//  Document.h
//  SQLite Inspector
//
//  Created by R. Tony Goold on 07.07.2016.
//  Copyright © 2016 WP Technology Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class DBReader;

@interface Document : NSDocument

@property (nonatomic, strong, readonly) DBReader *reader;

- (IBAction)visualizeDocument:(id)sender;

@end
