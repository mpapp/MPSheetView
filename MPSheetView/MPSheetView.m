//
//  MPSheetView.m
//  MPSheetViewExample
//
//  Created by Matias Piipari on 19/12/2014.
//  Copyright (c) 2014 Matias Piipari. All rights reserved.
//

#import "MPSheetView.h"

#import <objc/runtime.h>

@interface MPSheetView ()
@property (readwrite) id<MPSheetItem> selectedItem;
@end

@implementation MPSheetView

- (void)reloadData {
    [self setUpScene];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.ortographicScale = 1.0f;
    self.backgroundDiffuseColor = [NSColor colorWithCalibratedWhite:0.4 alpha:1.0];
    self.backgroundAmbientColor = [NSColor colorWithCalibratedWhite:0.1 alpha:1.0];
    
    self.selectionSpotlightColor = [NSColor colorWithWhite:0.37 alpha:1.0f];
    
    self.titleFontSize = 12.0f;
    self.subtitleFontSize = 10.0f;
}

typedef NS_OPTIONS(NSUInteger, MPSheetViewNodeCategory) {
    MPSheetViewNodeCategoryUnknown,
    MPSheetViewNodeCategoryBackground,
    MPSheetViewNodeCategoryCover,
    MPSheetViewNodeCategoryText
};

static const CGFloat MPSheetViewMasterNodeYAdjustment = 0.0;
static const CGFloat MPSheetViewCameraZDistance = 2.0f;

- (NSArray *)nodesForSheetItems:(NSArray *)sheetItems midpoint:(SCNVector3 *)midpoint {
    NSMutableArray *nodes = [NSMutableArray new];
    
    NSURL *sceneURL = [[NSBundle bundleForClass:self.class] URLForResource:@"book-cover" withExtension:@"dae"]; NSParameterAssert(sceneURL);
    NSError *err = nil;
    SCNScene *scene = [SCNScene sceneWithURL:sceneURL options:@{ SCNSceneSourceCreateNormalsIfAbsentKey : @(YES) } error:&err];
    NSParameterAssert(!err);
    
    static const CGFloat hOffset = 1.4f;
    
    NSUInteger count = [self.dataSource numberOfSheetsInSheetView:self];
    
    NSParameterAssert(self.dataSource);
    for (NSUInteger i = 0; i < count; i++) {
        id<MPSheetItem> item = [self.dataSource sheetView:self itemAtIndex:i];
        
        // master node contains the sheet cover image node + the text node.
        SCNNode *masterNode = [[SCNNode alloc] init];
        masterNode.name = item.title;
        masterNode.categoryBitMask = MPSheetViewNodeCategoryBackground;
        
        
        masterNode.position = SCNVector3Make(i * hOffset, MPSheetViewMasterNodeYAdjustment, 0);
        
        CGFloat aspectRatio = item.coverImage.size.width / item.coverImage.size.height;
        
        SCNGeometry *nodeGeom = [[[[scene rootNode] childNodeWithName:@"box_object1" recursively:YES] geometry] copy];
        SCNNode *coverNode = [SCNNode nodeWithGeometry:nodeGeom];
        coverNode.name = @"cover";
        
        coverNode.scale = SCNVector3Make(aspectRatio, 1.0, 0.01);
        coverNode.position = SCNVector3Make(0, 0, 0);
        
        SCNMaterial *coverMaterial = [[[SCNMaterial alloc] init] copy];
        coverMaterial.diffuse.contents = item.coverImage;
        coverMaterial.diffuse.intensity = 0.9;
        
        coverMaterial.ambient.contents = [NSColor colorWithWhite:0.4 alpha:1.0];
        coverMaterial.ambient.intensity = 1.0f;
        
        coverMaterial.emission.contents = [NSColor blackColor];
        
        coverMaterial.diffuse.mipFilter = SCNFilterModeLinear;
        coverMaterial.diffuse.minificationFilter = SCNFilterModeLinear;
        coverMaterial.diffuse.magnificationFilter = SCNFilterModeLinear;
        
        coverMaterial.ambient.mipFilter = SCNFilterModeLinear;
        coverMaterial.ambient.minificationFilter = SCNFilterModeLinear;
        coverMaterial.ambient.magnificationFilter = SCNFilterModeLinear;
        
        coverMaterial.specular.mipFilter = SCNFilterModeLinear;
        coverMaterial.specular.minificationFilter = SCNFilterModeLinear;
        coverMaterial.specular.magnificationFilter = SCNFilterModeLinear;
        
        coverMaterial.emission.mipFilter = SCNFilterModeLinear;
        coverMaterial.emission.minificationFilter = SCNFilterModeLinear;
        coverMaterial.emission.magnificationFilter = SCNFilterModeLinear;
        
        coverNode.categoryBitMask = MPSheetViewNodeCategoryCover;
        
        coverNode.geometry.materials = @[ coverMaterial ];
        coverMaterial.lightingModelName = SCNLightingModelLambert;

        [masterNode addChildNode:coverNode];
        [self spotlightNodeForNode:masterNode];

        [self textNodesForMasterNode:masterNode coverNode:coverNode item:item];
        
        objc_setAssociatedObject(masterNode, "sheetItem", item, OBJC_ASSOCIATION_RETAIN);
        
        [nodes addObject:masterNode];
    }
    
    if (midpoint) {
        *midpoint = SCNVector3Make(hOffset * (count - 1) * .5, - self.verticalPositionAdjustment, 0.05);
    }
    
    return nodes.copy;
}

- (NSArray *)textNodesForMasterNode:(SCNNode *)masterNode coverNode:(SCNNode *)coverNode item:(id<MPSheetItem>)item {
    SCNText *titleTextGeom = [SCNText textWithString:item.title extrusionDepth:0.0];
    titleTextGeom.font = [NSFont systemFontOfSize:self.titleFontSize];
    SCNNode *titleTextNode = [SCNNode new];
    titleTextNode.geometry = titleTextGeom;
    
    SCNText *subtitleTextGeom = [SCNText textWithString:item.subtitle extrusionDepth:0.0];
    subtitleTextGeom.font = [NSFont systemFontOfSize:self.subtitleFontSize];
    SCNNode *subtitleTextNode = [SCNNode new];
    subtitleTextNode.geometry = subtitleTextGeom;
    
    SCNMaterial *textMaterial = [[SCNMaterial alloc] init];
    textMaterial.diffuse.contents = [NSColor whiteColor];
    textMaterial.specular.contents = [NSColor whiteColor];
    textMaterial.ambient.contents = [NSColor whiteColor];
    
    titleTextNode.categoryBitMask = MPSheetViewNodeCategoryText;
    
    CGFloat textScale = 0.008;
    titleTextNode.geometry.materials = @[textMaterial];
    titleTextNode.position = SCNVector3Make(-titleTextGeom.textSize.width * 0.5 * textScale, - coverNode.scale.y * 0.68, 0.0);
    titleTextNode.scale = SCNVector3Make(textScale, textScale, textScale);
    
    subtitleTextNode.geometry.materials = @[textMaterial];
    subtitleTextNode.position = SCNVector3Make(-subtitleTextGeom.textSize.width * 0.5 * textScale, - coverNode.scale.y * 0.78, 0.0);
    subtitleTextNode.scale = SCNVector3Make(textScale, textScale, textScale);
    
    subtitleTextNode.categoryBitMask = MPSheetViewNodeCategoryText;
    
    objc_setAssociatedObject(masterNode, "sheetItem", item, OBJC_ASSOCIATION_RETAIN);
    
    [masterNode addChildNode:titleTextNode];
    [masterNode addChildNode:subtitleTextNode];

    return @[ titleTextNode, subtitleTextNode ];
}

- (SCNNode *)existingSpotlightNodeForNode:(SCNNode *)node {
    SCNNode *n = [node childNodeWithName:@"primarySpot" recursively:NO];
    
    SCNNode *parentN = objc_getAssociatedObject(n, "node");
    NSParameterAssert(parentN == n.parentNode);
    
    return n;
}

- (SCNNode *)spotlightNodeForNode:(SCNNode *)node {
    SCNNode *existingSpot = nil;
    if ((existingSpot = [self existingSpotlightNodeForNode:node]))
        return existingSpot;
    
    SCNNode *spotNode = [[SCNNode alloc] init];
    spotNode.light = [[SCNLight alloc] init];
    spotNode.light.type = SCNLightTypeSpot;
    spotNode.light.castsShadow = YES;
    spotNode.light.spotInnerAngle = M_PI * 2.2;
    spotNode.light.spotOuterAngle = spotNode.light.spotInnerAngle * 1.6;
    spotNode.light.shadowSampleCount = 2;
    spotNode.light.shadowRadius = 2;
    spotNode.light.shadowBias = 1.0f;
    spotNode.light.attenuationEndDistance = 100.0f;
    
    spotNode.light.color = [NSColor blackColor]; // needs to be put on separately by selecting an object.
    spotNode.name = @"primarySpot";
    
    spotNode.light.categoryBitMask = MPSheetViewNodeCategoryCover | MPSheetViewNodeCategoryBackground;
    
    spotNode.position = SCNVector3Make(0, 1.0, 8.0);
    spotNode.constraints = @[[SCNLookAtConstraint lookAtConstraintWithTarget:node]];
    [node addChildNode:spotNode];
    
    objc_setAssociatedObject(spotNode, "node", node, OBJC_ASSOCIATION_ASSIGN);
    
    return spotNode;
}

- (SCNNode *)sheetItemsRootNode {
    return [self.scene.rootNode childNodeWithName:@"sheetItemsRootNode" recursively:YES];
}

- (NSArray *)sheetItemNodes {
    return [self.scene.rootNode childNodesPassingTest:
            ^BOOL(SCNNode *child, BOOL *stop) {
                id<MPSheetItem> item = objc_getAssociatedObject(child, "sheetItem");
                return item != nil;
            }];
}

- (NSArray *)sheetItems {
    NSMutableArray *items = [NSMutableArray new];
    
    NSParameterAssert(self.dataSource);
    for (NSUInteger i = 0, cnt = [self.dataSource numberOfSheetsInSheetView:self]; i < cnt; i++)
        [items addObject:[self.dataSource sheetView:self itemAtIndex:i]];
    
    return items.copy;
}

- (void)refreshItems {
    // remove existing sheetItemsRootNode.
    [[self sheetItemsRootNode] removeFromParentNode];
    [[self sheetItemsMidpointNode] removeFromParentNode];
    
    SCNNode *sheetItemsRootNode = [[SCNNode alloc] init];
    sheetItemsRootNode.name = @"sheetItemsRootNode";
    [self.scene.rootNode addChildNode:sheetItemsRootNode];
    
    // add new sheet items as the children of sheetItemsRootNode.
    
    SCNVector3 midpointV;
    for (SCNNode *node in [self nodesForSheetItems:self.sheetItems midpoint:&midpointV]) {
        [sheetItemsRootNode addChildNode:node];
    }
    
    SCNNode *midpointNode = [SCNNode new];
    midpointNode.name = @"sheetItemsCenter";
    midpointNode.position = midpointV;
    //[midpointNode setGeometry:[SCNSphere sphereWithRadius:0.1]];
    
    [self.scene.rootNode addChildNode:midpointNode];
}

- (SCNNode *)sheetItemsMidpointNode {
    return [self.scene.rootNode childNodeWithName:@"sheetItemsCenter" recursively:YES];
}

- (void)setUpLighting {
    SCNNode *cameraNode = [self primaryCameraNode]; NSParameterAssert(cameraNode);

    [cameraNode childNodeWithName:@"primaryOmniLeft" recursively:YES];
    [cameraNode childNodeWithName:@"primaryOmniRight" recursively:YES];
    [cameraNode childNodeWithName:@"primaryAmbient" recursively:YES];

    SCNNode *omniNodeLeft = [[SCNNode alloc] init];
    omniNodeLeft.light = [[SCNLight alloc] init];
    omniNodeLeft.light.type = SCNLightTypeOmni;
    omniNodeLeft.light.color = [NSColor colorWithWhite:0.3 alpha:1.0];
    omniNodeLeft.name = @"primaryOmniRight";
    omniNodeLeft.position = SCNVector3Make(5, 0, 2);
    [cameraNode addChildNode:omniNodeLeft];
    
    SCNNode *omniNodeCenter = [[SCNNode alloc] init];
    omniNodeCenter.light = [[SCNLight alloc] init];
    omniNodeCenter.light.type = SCNLightTypeOmni;
    omniNodeCenter.light.color = [NSColor colorWithWhite:0.55 alpha:1.0];
    omniNodeCenter.name = @"primaryOmni";
    omniNodeCenter.position = SCNVector3Make(0, 0, 10);
    [cameraNode addChildNode:omniNodeCenter];
    
    SCNNode *omniNodeRight = [[SCNNode alloc] init];
    omniNodeRight.light = [[SCNLight alloc] init];
    omniNodeRight.light.type = SCNLightTypeOmni;
    omniNodeRight.light.color = [NSColor colorWithWhite:0.3 alpha:1.0];
    omniNodeRight.name = @"primaryOmniLeft";
    omniNodeRight.position = SCNVector3Make(-5, 0, 2);
    [cameraNode addChildNode:omniNodeRight];
    
    SCNLight *ambientLight = [SCNLight new];
    SCNNode *ambientLightNode = [SCNNode new];
    
    ambientLight.type = SCNLightTypeAmbient;
    ambientLight.color = [NSColor colorWithCalibratedWhite:0.2 alpha:1.0];
    ambientLightNode.light = ambientLight;
    
    ambientLightNode.name = @"primaryAmbient";
    
    [cameraNode addChildNode:ambientLightNode];
}

- (SCNNode *)primaryCameraNode {
    return [self.scene.rootNode childNodeWithName:@"primaryCamera" recursively:YES];
}

- (void)setUpCameraPointedAtTarget:(SCNNode *)targetNode {
    
    [[self.scene.rootNode childNodeWithName:@"primaryCamera" recursively:YES] removeFromParentNode];
    
    SCNCamera *camera = [SCNCamera camera];
    camera.usesOrthographicProjection = YES;
    camera.orthographicScale = self.ortographicScale;
    camera.automaticallyAdjustsZRange = YES;
    
    SCNNode *cameraNode = [[SCNNode alloc] init];
    cameraNode.position = SCNVector3Make(targetNode.position.x, targetNode.position.y, MPSheetViewCameraZDistance);
    cameraNode.camera = camera;
    cameraNode.name = @"primaryCamera";
    
    [self.scene.rootNode addChildNode:cameraNode];
}

- (void)setUpFloor {
    SCNFloor *floor = [SCNFloor floor];
    
    floor.reflectivity = 0.0;
    floor.firstMaterial.diffuse.contents = [NSColor grayColor];
    floor.reflectionFalloffEnd = 0.5f;
    
    SCNNode *floorNode = [SCNNode nodeWithGeometry:floor];
    floorNode.position = SCNVector3Make(0, -0.85, -0.2);
    
    floorNode.rotation = SCNVector4Make(1, 0, 0, M_PI * 1.4);

    floorNode.geometry.firstMaterial.diffuse.contents = self.backgroundDiffuseColor;
    floorNode.geometry.firstMaterial.ambient.contents = self.backgroundAmbientColor;
    
    floorNode.categoryBitMask = MPSheetViewNodeCategoryBackground;
    
    [self.scene.rootNode addChildNode:floorNode];
}

- (void)setUpScene {
    SCNScene *viewScene = [SCNScene scene];
    self.scene = viewScene;
    
    self.autoenablesDefaultLighting = YES;
    self.backgroundColor = [NSColor colorWithCalibratedWhite:0.1 alpha:1.0];
    
    [self refreshItems];
    
    [self setUpFloor];
    
    
    if (self.centerContent) {
        if (self.sheetItemNodes.count > 0)
            NSParameterAssert(self.sheetItemsMidpointNode);
        
        [self setUpCameraPointedAtTarget:self.sheetItemsMidpointNode];
    } else {
        [self setUpCameraPointedAtTarget:self.sheetItemNodes.firstObject];
        
        // selecting moves the camera, then after that select nil to remove the selection highlight.
        [self selectNode:self.sheetItemNodes.firstObject];
        [self selectNode:nil];
    }
    
    [self setUpLighting];


    /*
    [SCNTransaction begin];
    SCNTransaction.AnimationDuration = 30.0;
    [(SCNNode *)self.sheetItemNodes.firstObject setRotation:SCNVector4Make(0, 1, 0, (float)M_PI * 4)];
    [SCNTransaction commit];
     */
}

#pragma mark -

- (id<MPSheetItem>)sheetItemForNode:(SCNNode *)node {
    id<MPSheetItem> item = objc_getAssociatedObject(node, "sheetItem");
    if (!item) {
        item = objc_getAssociatedObject(node.parentNode, "sheetItem");
    }
    
    return item;
}

- (void)selectNode:(SCNNode *)node {
    id<MPSheetItem> item = [self sheetItemForNode:node];
    
    for (SCNNode *n in self.sheetItemNodes) {
        [n.geometry.firstMaterial.emission removeAllAnimations];
        for (SCNNode *cn in n.childNodes) {
            [cn.geometry.firstMaterial.emission removeAllAnimations];
        }
        
        SCNNode *lightNode = [self existingSpotlightNodeForNode:n];
        
        if (![lightNode.light.color isEqual:[NSColor blackColor]]) {
            CABasicAnimation *spotAnimation = [CABasicAnimation animationWithKeyPath:@"color"];
            spotAnimation.toValue = [NSColor blackColor];
            spotAnimation.fromValue = self.selectionSpotlightColor;
            spotAnimation.repeatCount = 1;
            spotAnimation.autoreverses = NO;
            spotAnimation.duration = 0.2;
            spotAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];

            lightNode.light.color = NSColor.blackColor;
            [lightNode.light addAnimation:spotAnimation forKey:@"spotColor"];
        }

    }
    
    for (id<MPSheetItem> item in self.sheetItems) {
        SCNNode *spotlightNode = [self existingSpotlightNodeForNode:[self masterNodeForSheetItem:item]];
        spotlightNode.light.color = [NSColor blackColor];
    }
    
    if (node == nil) {
        self.selectedItem = nil;
        return;
    } else {
        self.selectedItem = item;
    }
    
    if (!item) {
        self.selectedItem = nil;
        return;
    }
    
    // Convert the geometry element index to a material index.
    if (self.centerSelection) {
        [SCNTransaction begin];
        [SCNTransaction setAnimationDuration:0.5];
        self.primaryCameraNode.position = SCNVector3Make(node.parentNode.position.x, node.parentNode.position.y - self.verticalPositionAdjustment, MPSheetViewCameraZDistance);
        [SCNTransaction commit];
    }

    CABasicAnimation *emissionAnimation = [CABasicAnimation animationWithKeyPath:@"contents"];
    emissionAnimation.toValue = [NSColor colorWithHue:224.0f / 255.0f saturation:30.0f / 255.0f brightness:0.05f alpha:1.0f];
    emissionAnimation.fromValue = [NSColor colorWithHue:224.0f / 255.0f saturation:30.0f / 255.0f brightness:0.0f alpha:1.0f];
    emissionAnimation.repeatCount = MAXFLOAT;
    emissionAnimation.autoreverses = YES;
    emissionAnimation.duration = 2.5;
    emissionAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];

    SCNNode *lightNode = [self existingSpotlightNodeForNode:node.parentNode];
    CABasicAnimation *spotAnimation = [CABasicAnimation animationWithKeyPath:@"color"];
    spotAnimation.toValue = self.selectionSpotlightColor;
    spotAnimation.fromValue = [NSColor blackColor];
    spotAnimation.repeatCount = 1;
    spotAnimation.autoreverses = NO;
    spotAnimation.duration = 0.5;
    spotAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    
    lightNode.light.color = self.selectionSpotlightColor;
    [lightNode.light addAnimation:spotAnimation forKey:@"spotColor"];
}

- (void)mouseUp:(NSEvent *)event {
    // Convert the mouse location in screen coordinates to local coordinates, then perform a hit test with the local coordinates.
    NSPoint mouseLocation = [self convertPoint:[event locationInWindow] fromView:nil];
    NSArray *hits = [self hitTest:mouseLocation options:nil];
    SCNHitTestResult *hit = hits[0];
    
    if (event.clickCount < 2) {
        if (hits.count > 0 && !self.selectedItem) {
            [self selectNode:hit.node];
        }
        else {
            [self selectNode:nil];
        }
    }
    else {
        if (!self.selectedItem) {
            [self selectNode:hit.node];
        }
        id<MPSheetItem> item = [self sheetItemForNode:hit.node];
        [self.dataSource sheetView:self didSelectItem:item];
    }
    
    [super mouseUp:event];
}

- (SCNNode *)masterNodeForSheetItem:(id<MPSheetItem>)item {
    return [self.sheetItemNodes filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(SCNNode *node, NSDictionary *bindings) {
        return [objc_getAssociatedObject(node, "sheetItem") isEqual:item];
    }]].firstObject;
}

- (SCNNode *)coverNodeForSheetItem:(id<MPSheetItem>)item {
    return [[self masterNodeForSheetItem:item] childNodeWithName:@"cover" recursively:YES];
}

- (SCNNode *)selectedMasterNode {
    if (!self.selectedItem)
        return nil;
    
    return [self masterNodeForSheetItem:self.selectedItem];
}

- (void)keyDown:(NSEvent *)theEvent {
    switch(theEvent.keyCode) {
        case 126: { // up arrow
            
        }
        case 125: { // down arrow
            
        }
        case 124: { // right arrow
            if (self.selectedItem) {
                NSUInteger selectedIndex = [self.sheetItems indexOfObject:self.selectedItem];
                if ((selectedIndex < ([self.dataSource numberOfSheetsInSheetView:self] - 1)) && (selectedIndex != NSNotFound)) {
                    [self selectNode:[self coverNodeForSheetItem:[self.dataSource sheetView:self itemAtIndex:selectedIndex + 1]]];
                }
            }
            else if ([self.dataSource numberOfSheetsInSheetView:self] > 0) {
                [self selectNode:[self coverNodeForSheetItem:[self.dataSource sheetView:self itemAtIndex:0]]];
            }
            break;
        }
        case 123: { // left arrow
            if (self.selectedItem) {
                NSUInteger selectedIndex = [self.sheetItems indexOfObject:self.selectedItem];
                if (selectedIndex > 0 && selectedIndex != NSNotFound) {
                    [self selectNode:[self coverNodeForSheetItem:[self.dataSource sheetView:self itemAtIndex:selectedIndex - 1]]];
                }
            }
            else if ([self.dataSource numberOfSheetsInSheetView:self] > 0) {
                [self selectNode:[self coverNodeForSheetItem:[self.dataSource sheetView:self itemAtIndex:0]]];
            }
        }
    }
}

@end
