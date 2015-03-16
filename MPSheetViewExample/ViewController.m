//
//  ViewController.m
//  MPSheetViewExample
//
//  Created by Matias Piipari on 18/12/2014.
//  Copyright (c) 2014 Matias Piipari. All rights reserved.
//

#import "ViewController.h"

#import "MPSheetViewController.h"

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

- (void)prepareForSegue:(NSStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"EmbedSheetViewController"]) {
        MPSheetViewController *sheetViewC = segue.destinationController;
        [sheetViewC view];
        
        sheetViewC.sheetItems =
        @[[[MPSimpleSheetItem alloc] initWithTitle:@"Getting Started" subtitle:@"Manuscripts.app Team" coverImage:[MPSheetViewController imageWithName:@"teh-manual"]],
          [[MPSimpleSheetItem alloc] initWithTitle:@"Tractatus Logico-…" subtitle:@"Wittgenstein (1921)" coverImage:[MPSheetViewController imageWithName:@"tractatus-logico-philosophicus"]],
          [[MPSimpleSheetItem alloc] initWithTitle:@"Origin of Species" subtitle:@"Darwin (1859)" coverImage:[MPSheetViewController imageWithName:@"origin-of-species"]],
          [[MPSimpleSheetItem alloc] initWithTitle:@"Percutaneous and surgical…" subtitle:@"Putensen (2014)" coverImage:[MPSheetViewController imageWithName:@"biomed"]],
          [[MPSimpleSheetItem alloc] initWithTitle:@"On Computable …" subtitle:@"Turing (1936)" coverImage:[MPSheetViewController imageWithName:@"Turing_Paper_1936"]]];
        
    }
}

@end
