//
//  MPSheetViewController.m
//  MPSheetViewExample
//
//  Created by Matias Piipari on 18/12/2014.
//  Copyright (c) 2014 Matias Piipari. All rights reserved.
//

#import "MPSheetViewController.h"

#import "MPSheetView.h"

#import <objc/runtime.h>

@implementation MPSimpleSheetItem

- (instancetype)initWithTitle:(NSString *)title subtitle:(NSString *)subtitle coverImage:(NSImage *)coverImage {
    if (self) {
        _title = title;
        _subtitle = subtitle;
        _coverImage = coverImage;
    }
    
    return self;
}

@end

@interface MPSheetViewController ()

@end

@implementation MPSheetViewController

+ (NSImage *)imageWithName:(NSString *)imageName {
    return [[NSImage alloc] initWithData:[NSData dataWithContentsOfURL:[[NSBundle bundleForClass:self] URLForResource:imageName withExtension:@"png"]]];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.sheetItems = @[];
}

- (void)setSheetItems:(NSArray *)sheetItems {
    _sheetItems = sheetItems;
    [self.sheetView reloadData];
}

- (NSUInteger)numberOfSheetsInSheetView:(MPSheetView *)sheetView {
    return self.sheetItems.count;
}

- (id<MPSheetItem>)sheetView:(MPSheetView *)sheetView itemAtIndex:(NSUInteger)index {
    return self.sheetItems[index];
}

- (void)sheetView:(MPSheetView *)sheetView didSelectItem:(id<MPSheetItem>)item {
    NSParameterAssert(item);
}

- (NSMenu *)sheetView:(MPSheetView *)sheetView menuForItem:(id<MPSheetItem>)item {
    return nil;
}

@end
