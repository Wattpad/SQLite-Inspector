//
//  VisualizationViewController.m
//  SQLite Inspector
//
//  Created by R. Tony Goold on 02.08.2016.
//  Copyright © 2016 WP Technology Inc. All rights reserved.
//

#import "VisualizationViewController.h"

#import "Visualization.h"
#import "VisualizationGenerator.h"

@interface VisualizationViewController ()

@property (nonatomic, strong, readonly) VisualizationGenerator *generator;
@property (nonatomic, strong, nullable) Visualization *visualization;
@property (nonatomic) NSUInteger lastPopoverIndex;
@property (nonatomic, strong, nullable) NSPopover *lastPopover;

- (void)generateImage;

@end

@implementation VisualizationViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    NSClickGestureRecognizer *click = [[NSClickGestureRecognizer alloc] initWithTarget:self
                                                                                action:@selector(imageClicked:)];
    [self.imageView addGestureRecognizer:click];

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
        Visualization *visualization = [self.generator visualizationFittingSize:bounds];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.visualization = visualization;
            self.imageView.image = visualization.image;
            [indicator stopAnimation:self];
            [indicator removeFromSuperview];
        });
    });
}

- (NSString *)tooltipForPage:(NSUInteger)pageNumber {
    if (pageNumber == 0U) {
        return @"";
    }
    const DBPageType pageType = [self.visualization pageTypeAtIndex:pageNumber];
    NSMutableString *tooltip = [[NSMutableString alloc] initWithFormat:@"Page %lu: ", (unsigned long)pageNumber];
    switch (pageType) {
        case DBPageTypeBtree:
            [tooltip appendString:@"B-tree"];
            break;
        case DBPageTypeFreelist:
            [tooltip appendString:@"Free List"];
            break;
        case DBPageTypeLockByte:
            [tooltip appendString:@"Lock Byte"];
            break;
        case DBPageTypePayload:
            [tooltip appendString:@"Payload"];
            break;
        case DBPageTypePointerMap:
            [tooltip appendString:@"Pointer Map"];
            break;
        default:
            [tooltip appendString:@"Unknown"];
    }
    return tooltip;
}

- (IBAction)dismissPopover:(nullable id)sender {
    [self.lastPopover performClose:sender];
    self.lastPopover = nil;
    self.lastPopoverIndex = 0U;
}

- (IBAction)imageClicked:(NSClickGestureRecognizer *)click {
    if (!self.visualization) {
        return;
    }

    const CGPoint point = [click locationInView:self.imageView];
    CGPoint imagePoint = point;
    if (!self.imageView.flipped) {
        // Compensate for inverted Y-axis
        imagePoint.y = self.imageView.bounds.size.height - point.y;
    }
    const NSUInteger pageNumber = [self.visualization pageIndexAtPoint:imagePoint];
    if (pageNumber == self.lastPopoverIndex) {
        [self dismissPopover:click];
        return;
    }

    NSString *tooltip = [self tooltipForPage:pageNumber];
    if (tooltip.length == 0U) {
        NSLog(@"Click does not correspond to a database page");
        [self dismissPopover:click];
        return;
    }

    NSViewController *tooltipViewController = [self.storyboard instantiateControllerWithIdentifier:@"Tooltip View Controller"];
    NSTextField *label = tooltipViewController.view.subviews[0];
    label.stringValue = tooltip;
    NSPopover *popover = [[NSPopover alloc] init];
    popover.contentViewController = tooltipViewController;
    popover.contentSize = [label sizeThatFits:label.bounds.size];
    popover.behavior = NSPopoverBehaviorTransient;
    NSRect rect = { point, CGSizeMake(1.0, 1.0) };
    [popover showRelativeToRect:rect ofView:self.imageView preferredEdge:NSRectEdgeMaxX];

    self.lastPopover = popover;
    self.lastPopoverIndex = pageNumber;
}

@end
