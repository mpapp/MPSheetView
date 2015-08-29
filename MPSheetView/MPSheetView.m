//
//  MPSheetView.m
//  MPSheetViewExample
//
//  Created by Matias Piipari on 19/12/2014.
//  Copyright (c) 2014 Matias Piipari. All rights reserved.
//

#import "MPSheetView.h"

#import <objc/runtime.h>

// TODO: the terminology is getting pretty overloaded (prepare, set up, refresh).
// TODO: Clean up the messy chained private methods.

@interface MPSheetView ()
@property (readwrite) id<MPSheetItem> selectedItem;

// TODO: Get rid of this retained property (you leak the previously rendered items).
@property (strong) NSArray *renderedSheetItems;
@end

@implementation MPSheetView

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.ortographicScale = 1.15f;
    self.backgroundDiffuseColor = [NSColor colorWithCalibratedWhite:0.4 alpha:1.0];
    self.backgroundAmbientColor = [NSColor colorWithCalibratedWhite:0.1 alpha:1.0];
    
    self.selectionSpotlightColor = [NSColor colorWithCalibratedHue:44.0f/360.0f
                                                        saturation:38.0f/100.0f
                                                        brightness:.27
                                                             alpha:1.0];
    
    self.titleFontSize = 12.0f;
    self.subtitleFontSize = 10.0f;
    self.textColor = [NSColor whiteColor];
    
    [self prepareScene];
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
    titleTextNode.name = @"title";
    
    SCNText *subtitleTextGeom = [SCNText textWithString:item.subtitle extrusionDepth:0.0];
    subtitleTextGeom.font = [NSFont systemFontOfSize:self.subtitleFontSize];
    SCNNode *subtitleTextNode = [SCNNode new];
    subtitleTextNode.name = @"subtitle";
    subtitleTextNode.geometry = subtitleTextGeom;
    
    SCNMaterial *textMaterial = [[SCNMaterial alloc] init];
    textMaterial.diffuse.contents = self.textColor;
    textMaterial.specular.contents = self.textColor;
    textMaterial.ambient.contents = self.textColor;
    
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

+ (void)performInMainQueueAfterDelay:(NSTimeInterval)delay
                               block:(void (^)(void))block
{
    int64_t delta = (int64_t)(1.0e9 * delay);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delta), dispatch_get_main_queue(), block);
}

- (void)refreshItems {
    SCNVector3 midpointV;
    NSArray *addedNodes = [self nodesForSheetItems:self.sheetItems midpoint:&midpointV];
    
    if ([self.renderedSheetItems isEqual:self.sheetItems])
        return; // we already rendered these ones.

    self.selectedItem = nil;
    self.renderedSheetItems = self.sheetItems;
    
    // remove existing sheetItemsRootNode.
    //[[self sheetItemsRootNode] removeFromParentNode];
    [[self sheetItemsMidpointNode] removeFromParentNode];
    
    SCNNode *sheetItemsRootNode = [self.scene.rootNode childNodeWithName:@"sheetItemsRootNode" recursively:YES];
    
    if (!sheetItemsRootNode) {
        sheetItemsRootNode = [[SCNNode alloc] init];
        sheetItemsRootNode.name = @"sheetItemsRootNode";
        [self.scene.rootNode addChildNode:sheetItemsRootNode];
    }
    
    BOOL previousItemsRemoved = sheetItemsRootNode.childNodes.count > 0;
    
    // add new sheet items as the children of sheetItemsRootNode.
    NSUInteger i = 0;
    for (SCNNode *node in sheetItemsRootNode.childNodes) {
        
        node.opacity = 1.0f;
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.065 * (CGFloat)i++ * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            CABasicAnimation *nodeRemovalAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
            
            SCNVector3 toPos = SCNVector3Make(node.position.x, -3, node.position.z);
            nodeRemovalAnimation.fromValue = [NSValue valueWithSCNVector3:node.position];
            nodeRemovalAnimation.toValue = [NSValue valueWithSCNVector3:toPos];
            nodeRemovalAnimation.repeatCount = 1;
            nodeRemovalAnimation.autoreverses = NO;
            nodeRemovalAnimation.duration = 3.5;
            nodeRemovalAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
            
            node.position = toPos;
            
            [node addAnimation:nodeRemovalAnimation forKey:@"nodeRemovalAnimation"];
        
            CABasicAnimation *nodeOpacityAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
            nodeOpacityAnimation.fromValue = @(1.0f);
            nodeOpacityAnimation.toValue = @(0.0f);
            nodeOpacityAnimation.repeatCount = 1;
            nodeOpacityAnimation.autoreverses = NO;
            nodeOpacityAnimation.duration = 0.35;
            nodeOpacityAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
            nodeOpacityAnimation.delegate = self;
            [nodeOpacityAnimation setValue:node forKey:@"animatedNode"];
            
            node.opacity = 0.0f;

            [node addAnimation:nodeOpacityAnimation forKey:@"nodeOpacityAnimation"];
        });
    }
    
    for (SCNNode *node in addedNodes) {
        [sheetItemsRootNode addChildNode:node];
    }
    
    SCNNode *midpointNode = [SCNNode new];
    midpointNode.name = @"sheetItemsCenter";
    midpointNode.position = midpointV;
    //[midpointNode setGeometry:[SCNSphere sphereWithRadius:0.1]];
    
    [self.scene.rootNode addChildNode:midpointNode];
    
    if (previousItemsRemoved) {
        for (SCNNode *node in addedNodes) {
            SCNVector3 p = node.position;
            SCNVector3 startP = SCNVector3Make(node.position.x, node.position.y + .8, node.position.z);
            CABasicAnimation *nodeAdditionAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
            nodeAdditionAnimation.fromValue = [NSValue valueWithSCNVector3:startP];
            nodeAdditionAnimation.toValue = [NSValue valueWithSCNVector3:p];
            nodeAdditionAnimation.repeatCount = 1;
            nodeAdditionAnimation.autoreverses = NO;
            nodeAdditionAnimation.duration = .8;
            nodeAdditionAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
            
            node.position = p;
            [node addAnimation:nodeAdditionAnimation forKey:@"nodeAdditionAnimation"];
        }
    }
    
    // fade in is done anyway
    NSUInteger j = 0;
    for (SCNNode *node in addedNodes) {
        node.opacity = 0.0f;
        
        dispatch_after(previousItemsRemoved
                        ? dispatch_time(DISPATCH_TIME_NOW, (.3 + 0.065 * (CGFloat)j++) * NSEC_PER_SEC)
                        : dispatch_time(DISPATCH_TIME_NOW, (0.065 * (CGFloat)j++) * NSEC_PER_SEC),
                       dispatch_get_main_queue(), ^{
            CABasicAnimation *nodeOpacityAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
            nodeOpacityAnimation.fromValue = @(0.0f);
            nodeOpacityAnimation.toValue = @(1.0f);
            nodeOpacityAnimation.repeatCount = 1;
            nodeOpacityAnimation.autoreverses = NO;
            nodeOpacityAnimation.duration = 0.5;
            nodeOpacityAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
            
            node.opacity = 1.0f;
            [node addAnimation:nodeOpacityAnimation forKey:@"nodeOpacityAnimation"];
        });
    }
}

// only the removal animation 'nodeOpacityAnimation' has its delegate set, hence no conditionals here.
-(void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    SCNNode *node = [anim valueForKey:@"animatedNode"];
    [node removeFromParentNode];
}

- (SCNNode *)sheetItemsMidpointNode {
    return [self.scene.rootNode childNodeWithName:@"sheetItemsCenter" recursively:YES];
}

- (void)setUpCamera {
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
    cameraNode.camera = camera;
    cameraNode.name = @"primaryCamera";
    [self.scene.rootNode addChildNode:cameraNode];
    [self pointCameraNode:cameraNode atTargetNode:targetNode];
    
    NSParameterAssert([self primaryCameraNode]);
    NSParameterAssert([self primaryCameraNode] == cameraNode);
}

- (void)pointCameraNode:(SCNNode *)cameraNode atTargetNode:(SCNNode *)targetNode {
    cameraNode.position = SCNVector3Make(targetNode.position.x, targetNode.position.y, MPSheetViewCameraZDistance);
}

- (void)setUpFloor {
    if ([self.scene.rootNode childNodeWithName:@"floor" recursively:NO])
        return;
    
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
    
    floorNode.name = @"floor";
    
    [self.scene.rootNode addChildNode:floorNode];
    
    NSParameterAssert([self.scene.rootNode childNodeWithName:@"floor" recursively:NO]);
}

- (void)prepareScene {
    SCNScene *viewScene = [SCNScene scene];
    self.scene = viewScene;
    
    self.autoenablesDefaultLighting = YES;
    self.backgroundColor = [NSColor colorWithCalibratedWhite:0.1 alpha:1.0];
    
    [self setUpFloor];
    
    [self setUpCamera];
    
    [self setUpLighting]; // lighting depends on camera, therefore after.
    
    [self pointCameraNode:[self primaryCameraNode] atTargetNode:self.sheetItemsMidpointNode];
}

- (void)reloadData {
    if (!self.scene) {
        [self prepareScene];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self refreshItems];
        [self pointCameraNode:[self primaryCameraNode] atTargetNode:self.sheetItemsMidpointNode];
    });
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

- (NSMenu *)menuForEvent:(NSEvent *)event {
    NSPoint mouseLocation = [self convertPoint:[event locationInWindow] fromView:nil];
    NSArray *hits = [self hitTest:mouseLocation options:nil];
    SCNHitTestResult *hit = hits[0];
    
    id<MPSheetItem> item = [self sheetItemForNode:hit.node];
    
    return [self.dataSource sheetView:self menuForItem:item];
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
            id<MPSheetItem> item = [self sheetItemForNode:hit.node];
            if (item) {
                [self selectNode:hit.node];
            }
            else {
                [self selectNode:nil];                
            }
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
