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

@interface ViewController () <ARSCNViewDelegate>
NS_ASSUME_NONNULL_BEGIN

@property (nonatomic, strong, readonly) ARSCNView *sceneView;
@property (nonatomic, strong) AnimatingUIImageView *imageView;
@property (nonatomic, strong, nullable) UILabel *userMessagesLabel;

@property (nonatomic) BOOL isReady;

@property (nonatomic, readonly) ARAugmentedRealityConfig *config;

@end

    
@implementation ViewController

- (instancetype)initWithConfig:(ARAugmentedRealityConfig *)config  {
    self = [super init];
    if (!self) return nil;

    _config = config;
    _sceneView = [[ARSCNView alloc] init];

    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // TODO: Properly set this up with autolayout
    self.sceneView.frame = self.view.frame;
    [self.view addSubview:self.sceneView];

    // Set the view's delegate
    self.sceneView.delegate = self;
    
    // Show statistics such as fps and timing information
    self.sceneView.showsStatistics = YES;
    
    // Create a new scene
    SCNScene *scene = [[SCNScene alloc] init];
    self.sceneView.debugOptions = ARSCNDebugOptionShowWorldOrigin | ARSCNDebugOptionShowFeaturePoints;

    self.sceneView.scene = scene;

    [self showUI];
}

- (IBAction)showUI
{
    if (self.imageView) { return; }

    UIView *backBG = [[UIView alloc] initWithFrame:self.view.bounds];
    backBG.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
    AnimatingUIImageView * iv = [[AnimatingUIImageView alloc] initWithFrame:CGRectMake(0, backBG.center.y - 350, backBG.bounds.size.width, 400)];
    self.imageView = iv;
    iv.contentMode = UIViewContentModeCenter;
    [self session:self.sceneView.session cameraDidChangeTrackingState:self.sceneView.session.currentFrame.camera];

    UILabel *messaging = [[UILabel alloc] initWithFrame:CGRectMake(40, backBG.center.y + 100, backBG.bounds.size.width-80, 200)];
//    messaging.backgroundColor = [UIColor redColor];
    messaging.textColor = [UIColor whiteColor];
    messaging.font = [UIFont systemFontOfSize:24];
    messaging.numberOfLines = -1;
    self.userMessagesLabel = messaging;
    [backBG addSubview: messaging];

    [backBG addSubview:iv];
    [self.view insertSubview:backBG aboveSubview:self.sceneView];

    UIGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(buttonTapped:)];
    [backBG addGestureRecognizer:tapGesture];
}

- (IBAction)buttonTapped:(UITapGestureRecognizer *)gesture
{
    if(!self.isReady) { return; }

    [gesture.view removeFromSuperview];

    CGFloat width = [[[[NSMeasurement alloc] initWithDoubleValue:self.config.size.width
                                                            unit:NSUnitLength.inches]
                      measurementByConvertingToUnit:NSUnitLength.meters]
                     doubleValue];
    ;
    CGFloat height = [[[[NSMeasurement alloc] initWithDoubleValue:self.config.size.height
                                                             unit:NSUnitLength.inches]
                       measurementByConvertingToUnit:NSUnitLength.meters]
                      doubleValue];

    SCNPlane *geometry = [SCNPlane planeWithWidth:width height:height];
    SCNMaterial *material = [[SCNMaterial alloc] init];
    material.diffuse.contents = self.config.image;
    geometry.materials = @[material];

    simd_float4x4 newLocationSimD = self.sceneView.session.currentFrame.camera.transform;
    SCNVector3 newLocation = SCNVector3Make(newLocationSimD.columns[3].x, newLocationSimD.columns[3].y, newLocationSimD.columns[3].z);

    SCNNode *work = [SCNNode nodeWithGeometry:geometry];
    work.position = newLocation;
    [self.sceneView.scene.rootNode addChildNode:work];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Create a session configuration
    ARWorldTrackingConfiguration *configuration = [ARWorldTrackingConfiguration new];

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

    self.isReady = camera.trackingState == ARTrackingStateNormal;
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
NS_ASSUME_NONNULL_END
@end


