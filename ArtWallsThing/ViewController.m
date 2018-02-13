//
//  ViewController.m
//  ArtWallsThing
//
//  Created by Orta Therox on 11/4/17.
//  Copyright © 2017 Orta Therox. All rights reserved.
//

@import ARKit;
@import SceneKit;

#import "ARAugmentedRealityConfig.h"
#import "AnimatingUIImageView.h"

#import "ViewController.h"
#import "WallViewSceneDelegate.h"

#import "SCNArtworkNode.h"

@interface ViewController () <ARSCNViewDelegate>
NS_ASSUME_NONNULL_BEGIN

@property (nonatomic, strong, readonly) ARSCNView *sceneView;

@property (nonatomic, strong, nullable) SCNNode *artwork;
@property (nonatomic, strong, nullable) SCNNode *plane;

@property (nonatomic, strong, nullable) AnimatingUIImageView *imageView;
@property (nonatomic, strong, nullable) UIView *bgView;
@property (nonatomic, strong, nullable) UILabel *userMessagesLabel;

@property (nonatomic, strong, nullable) UIButton *resetButton;

@property (nonatomic) BOOL isReady;

@property (nonatomic, strong, readonly) ARAugmentedRealityConfig *config;

@property (nonatomic, strong) id<ARSCNViewDelegate, ARInteractive, ARSessionDelegate> visualsDelegate;

@end

    
@implementation ViewController

- (instancetype)initWithConfig:(ARAugmentedRealityConfig *)config  {
    self = [super init];
    if (!self) return nil;

    _config = config;
    _sceneView = [[ARSCNView alloc] init];
    _visualsDelegate = [[WallViewSceneDelegate alloc] initWithSession:_sceneView.session config:config scene:_sceneView];

    return self;
}

- (void)viewDidLoad {
    self.view.backgroundColor = UIColor.whiteColor;
    [super viewDidLoad];

    self.sceneView.frame = self.view.frame;
    [self.view addSubview:self.sceneView];

    // Set the view's delegate
    self.sceneView.delegate = self;
    
    // Show statistics such as fps and timing information
//    self.sceneView.showsStatistics = YES;

    self.sceneView.session.delegate = self.visualsDelegate;
    
    // Create a new scene
    SCNScene *scene = [[SCNScene alloc] init];
//    self.sceneView.debugOptions = ARSCNDebugOptionShowWorldOrigin | ARSCNDebugOptionShowFeaturePoints;

    self.sceneView.scene = scene;

    UIButton *resetButton = [UIButton buttonWithType:UIButtonTypeSystem];
    resetButton.backgroundColor = [UIColor lightGrayColor];
    resetButton.tintColor = [UIColor whiteColor];

    [resetButton setTitle:@"Reset" forState:UIControlStateNormal];
    resetButton.translatesAutoresizingMaskIntoConstraints = false;

    [resetButton addTarget:self action:@selector(reset) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:resetButton];

    [self.view addConstraints: @[
        [resetButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [resetButton.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [resetButton.heightAnchor constraintEqualToConstant:44.0],
        [resetButton.widthAnchor constraintGreaterThanOrEqualToConstant:100.0]
    ]];
    self.resetButton = resetButton;

    [self showUI];
}

- (void)showUI {
    if (self.imageView) { return; }

    self.resetButton.hidden = YES;

    UIView *backBG = [[UIView alloc] initWithFrame:self.view.bounds];
    backBG.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.1];
    AnimatingUIImageView * iv = [[AnimatingUIImageView alloc] initWithFrame:CGRectMake(0, backBG.center.y - 350, backBG.bounds.size.width, 400)];
    iv.contentMode = UIViewContentModeCenter;
    self.imageView = iv;
    [self showTrackingMessageForCamera:nil];

    UILabel *messaging = [[UILabel alloc] initWithFrame:CGRectMake(40, backBG.center.y + 100, backBG.bounds.size.width-80, 200)];
    messaging.textColor = [UIColor whiteColor];
    messaging.font = [UIFont systemFontOfSize:24];
    messaging.numberOfLines = -1;
    self.userMessagesLabel = messaging;
//    [backBG addSubview: messaging];
//
//    [backBG addSubview:iv];
//    [self.view insertSubview:backBG aboveSubview:self.sceneView];

//    self.bgView = backBG;

    UIGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(buttonTapped:)];
    [self.sceneView addGestureRecognizer:tapGesture];
}

- (IBAction)buttonTapped:(UITapGestureRecognizer *)gesture
{
//    if(!self.isReady) { return; }

    self.resetButton.hidden = NO;

//    [gesture.view removeFromSuperview];
    [self.visualsDelegate tappedScreen:gesture];
    

//    SCNBox *box = [SCNArtworkNode nodeWithConfig:self.config];
//
//    simd_float4x4 newLocationSimD = self.sceneView.session.currentFrame.camera.transform;
//    SCNVector3 newLocation = SCNVector3Make(newLocationSimD.columns[3].x, newLocationSimD.columns[3].y, newLocationSimD.columns[3].z);
//
//    self.artwork = [SCNNode nodeWithGeometry:box];
//    self.artwork.position = newLocation;
//    [self.sceneView.scene.rootNode addChildNode:self.artwork];

    // To properly move the art in the real world, we project a vertical plane we can hitTest against later
    // TODO: I wonder if we can generate this automatically later, rather than having a hidden object in our 3D scene

    // There doesn't appear to be a way to flat-out create an infinite plane.
    // 1000x1000 meters seems like a sensible upper bound that doesn't destroy performance

//
//
//    SCNPlane *infinitePlane = [SCNPlane planeWithWidth:1000 height:1000];
//    self.plane = [SCNNode nodeWithGeometry:infinitePlane];
//    self.plane.position = newLocation;
//    self.plane.hidden = true;

//    [self.sceneView.scene.rootNode addChildNode: self.plane];
}

- (void)reset {
    [self.imageView removeFromSuperview];
    self.imageView = nil;

    [self.bgView removeFromSuperview];
    self.bgView = nil;

    [self.artwork removeFromParentNode];
    self.artwork = nil;

    [self.plane removeFromParentNode];
    self.plane = nil;

    [self showUI];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Create a session configuration
    ARWorldTrackingConfiguration *configuration = [ARWorldTrackingConfiguration new];
    configuration.planeDetection = ARPlaneDetectionVertical;

    // Run the view's session
    [self.sceneView.session runWithConfiguration:configuration];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    // Pause the view's session
    [self.sceneView.session pause];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - ARSCNViewDelegate

/*
// Override to create and configure nodes for anchors added to the view's session.
- (SCNNode *)renderer:(id<SCNSceneRenderer>)renderer nodeForAnchor:(ARAnchor *)anchor {
    SCNNode *node = [SCNNode new];
 
    // Add geometry to the node...
 
    return node;
}
*/

- (void)session:(ARSession *)session cameraDidChangeTrackingState:(ARCamera *)camera
{
    if (!self.isReady) {
        [self showTrackingMessageForCamera: camera];
    }

    self.isReady = camera.trackingState == ARTrackingStateNormal;
}

- (void)showTrackingMessageForCamera:(nullable ARCamera *)camera {
    if (!camera) {
        camera = self.sceneView.session.currentFrame.camera;
    }
    
    switch (camera.trackingState) {
        case ARTrackingStateNotAvailable:
        case ARTrackingStateLimited:
            [self.imageView start];
            self.userMessagesLabel.text = @"Please slowly move the camera around the room to start augmented reality";
            
            break;
        case ARTrackingStateNormal:
            [self.imageView stop];
            self.imageView.image = [UIImage imageNamed:@"putphoneagainstwall.png"];
            self.userMessagesLabel.text = @"Please put your phone at eye level against the wall where you want to see your work \n\nThen hold one finger on the screen for 2 seconds ";
    }
}

- (NSString *)stringForTrackingReason:(ARTrackingStateReason) reason {
    switch (reason) {
        case ARTrackingStateReasonNone:
            return nil;
        case ARTrackingStateReasonInitializing:
            return @"Loading";
        case ARTrackingStateReasonExcessiveMotion:
            return @"Too much movement";
        case ARTrackingStateReasonInsufficientFeatures:
            return @"Need to understand room better";
        case ARTrackingStateReasonRelocalizing:
            return @"Re-localizing";
    }
}

- (void)session:(ARSession *)session didFailWithError:(NSError *)error {
    // Present an error message to the user
    
}

- (void)sessionWasInterrupted:(ARSession *)session {
    // Inform the user that the session has been interrupted, for example, by presenting an overlay
    
}

- (void)sessionInterruptionEnded:(ARSession *)session {
    // Reset tracking and/or remove existing anchors if consistent tracking is required
}

- (void)renderer:(id<SCNSceneRenderer>)renderer didUpdateNode:(SCNNode *)node forAnchor:(ARAnchor *)anchor
{
    [self.visualsDelegate renderer:renderer didUpdateNode:node forAnchor:anchor];
}

- (void)renderer:(id <SCNSceneRenderer>)renderer didAddNode:(SCNNode *)node forAnchor:(ARAnchor *)anchor;
{
    [self.visualsDelegate renderer:renderer didAddNode:node forAnchor:anchor];
}

- (void)renderer:(id<SCNSceneRenderer>)renderer willRenderScene:(SCNScene *)scene atTime:(NSTimeInterval)time
{
    [self.visualsDelegate renderer:renderer willRenderScene:scene atTime:time];
}

- (void)session:(ARSession *)session didUpdateFrame:(ARFrame *)frame;
{
    [self.visualsDelegate session:session didUpdateFrame:frame];
}

#pragma mark - Touches
/**
 * The current implementation of moving art:
 * When you touch the screen, we check if your point hits the invisible plane
 * that we project out from the art's position (representing the wall, roughly).
 * If yes, immediately move the artwork there.
 */
- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event {
    if (touches.count != 1) { return; } // TODO
    if (!self.artwork) { return; }

    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self.sceneView];

    NSDictionary *options = @{
      SCNHitTestIgnoreHiddenNodesKey: @NO,
      SCNHitTestFirstFoundOnlyKey: @YES,
      SCNHitTestOptionSearchMode: @(SCNHitTestSearchModeAny)
    };

    NSArray <SCNHitTestResult *> *results = [self.sceneView hitTest:point options: options];
    for (SCNHitTestResult *result in results) {
        if ([@[self.plane, self.artwork] containsObject:result.node]) {
            self.artwork.position = result.worldCoordinates;
        }
    }
}

NS_ASSUME_NONNULL_END
@end


