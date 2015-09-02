//
//  MPSheetView.h
//  MPSheetViewExample
//
//  Created by Matias Piipari on 19/12/2014.
//  Copyright (c) 2014 Matias Piipari. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <SceneKit/SceneKit.h>

@class MPSheetView;

@protocol MPSheetItem <NSObject>
@property (readonly, copy) NSString *title;
@property (readonly, copy) NSString *subtitle;
@property (readonly) NSImage *coverImage;
@end

@protocol MPSheetViewDataSource <NSObject>

- (NSUInteger)numberOfSheetsInSheetView:(MPSheetView *)sheetView;

- (id<MPSheetItem>)sheetView:(MPSheetView *)sheetView itemAtIndex:(NSUInteger)index;

- (NSMenu *)sheetView:(MPSheetView *)sheetView menuForItem:(id<MPSheetItem>)item;

// TODO: separate out a delegate protocol from the data source protocol.
- (void)sheetView:(MPSheetView *)sheetView didSelectItem:(id<MPSheetItem>)item;

- (void)sheetView:(MPSheetView *)sheetView shouldPreviewItem:(id<MPSheetItem>)item;

@end

IB_DESIGNABLE
@interface MPSheetView : SCNView

/** Centers the view on the currently selected item. */
@property (readwrite) IBInspectable BOOL centerSelection;

/** Centers at the midpoint of the content whenever reloadData is called. */
@property (readwrite) IBInspectable BOOL centerContent;

/** The ortographic scale of the scene. The smaller the value, the larger the sheets are. */
@property (readwrite) IBInspectable CGFloat ortographicScale;

@property (readwrite) IBInspectable NSColor *backgroundDiffuseColor;

@property (readwrite) IBInspectable NSColor *backgroundAmbientColor;

@property (readwrite) IBInspectable NSColor *textColor;

/** The sheets + text are adjusted vertically by this much from being vertically centre aligned. */
@property (readwrite) IBInspectable CGFloat verticalPositionAdjustment;

@property (readwrite) IBInspectable NSColor *selectionSpotlightColor;

/** Item title font (by default 12.0f sized system font) */
@property (readwrite) IBInspectable CGFloat titleFontSize;

/** Item subtitle font (by default 10.0f sized system font) */
@property (readwrite) IBInspectable CGFloat subtitleFontSize;

@property (readwrite, weak) IBOutlet id<MPSheetViewDataSource> dataSource;

- (void)reloadData;

@property (readonly) id<MPSheetItem> selectedItem;

@end
