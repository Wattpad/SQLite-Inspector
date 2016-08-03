//
//  VisualizationViewController.m
//  SQLite Inspector
//
//  Created by R. Tony Goold on 02.08.2016.
//  Copyright © 2016 WP Technology Inc. All rights reserved.
//

#import "VisualizationViewController.h"

#import "VisualizationGenerator.h"

@interface VisualizationViewController ()

@property (nonatomic, strong, readonly) VisualizationGenerator *generator;

- (void)generateImage;

@end

@implementation VisualizationViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    if (!self.imageView.image && self.generator) {
        [self generateImage];
    }
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    if (self.viewLoaded) {
        [self generateImage];
    }
}

- (VisualizationGenerator *)generator {
    return (VisualizationGenerator *)self.representedObject;
}

- (void)generateImage {
    NSProgressIndicator *indicator = [[NSProgressIndicator alloc] init];
    indicator.style = NSProgressIndicatorSpinningStyle;
    [indicator sizeToFit];
    NSRect frame = indicator.frame;
    const CGSize bounds = self.view.bounds.size;
    frame.origin.x = floor((bounds.width - frame.size.width) / 2.0);
    frame.origin.y = floor((bounds.height - frame.size.height) / 2.0);
    indicator.frame = frame;

    [self.view addSubview:indicator];
    [indicator startAnimation:self];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSImage *image = [self.generator generateImageFittingSize:bounds];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.imageView.image = image;
            [indicator stopAnimation:self];
            [indicator removeFromSuperview];
        });
    });
}

@end
