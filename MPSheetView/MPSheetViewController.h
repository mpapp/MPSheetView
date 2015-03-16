//
//  MPSheetViewController.h
//  MPSheetViewExample
//
//  Created by Matias Piipari on 18/12/2014.
//  Copyright (c) 2014 Matias Piipari. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <SceneKit/SceneKit.h>

#import "MPSheetView.h"

@class SCNView, MPSheetView;

@interface MPSimpleSheetItem : NSObject <MPSheetItem>
@property (readwrite, copy) NSString *title;
@property (readwrite, copy) NSString *subtitle;
@property (readwrite) NSImage *coverImage;

- (instancetype)initWithTitle:(NSString *)title
                     subtitle:(NSString *)subtitle
                   coverImage:(NSImage *)coverImage;

@end


@interface MPSheetViewController : NSViewController <MPSheetViewDataSource>

/** Load example image from the sheet view framework. */
+ (NSImage *)imageWithName:(NSString *)imageName;

@property (readwrite, weak) IBOutlet MPSheetView *sheetView;

@property (readwrite, nonatomic) NSArray *sheetItems;

@end
