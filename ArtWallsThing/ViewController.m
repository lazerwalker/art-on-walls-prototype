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

typedef void (^OnboardingStepBlock)(void);

NS_ENUM(NSUInteger, OnboardingStep) {
    OnboardingStepDetectingPlanes,
    OnboardingStepFinishedDetectingPlanes,
    OnboardingStepPlacePhoneOnWall,
    OnboardingStepWallDetected,
    OnboardingStepViewing
};


@interface ViewController () <ARSCNViewDelegate>
NS_ASSUME_NONNULL_BEGIN

@property (nonatomic, strong, readonly) ARSCNView *sceneView;

@property (nonatomic, strong, nullable) SCNNode *artwork;
@property (nonatomic, strong, nullable) SCNNode *plane;

@property (nonatomic, strong, nullable) AnimatingUIImageView *imageView;
@property (nonatomic, strong, nullable) UIView *bgView;
@property (nonatomic, strong, nullable) UILabel *userMessagesLabel;

@property (nonatomic, strong, nullable) UIButton *button;
@property (nonatomic, strong, nullable) UILabel *textLabel;

@property (nonatomic) BOOL isReady;

@property (nonatomic, copy) NSArray<OnboardingStepBlock> *steps;
@property (nonatomic, assign) NSInteger currentStep;

@property (nonatomic, strong, readonly) ARAugmentedRealityConfig *config;

@end

@implementation ViewController

- (instancetype)initWithConfig:(ARAugmentedRealityConfig *)config  {
    self = [super init];
    if (!self) return nil;

    _config = config;
    _sceneView = [[ARSCNView alloc] init];

    // TODO: This might be clearer if it's a dict that's explicitly keyed by enum?
    self.steps = @[
        ^{
            self.textLabel.hidden = NO;
            self.textLabel.text = @"Slowly pan the room with your phone";

            self.button.hidden = YES;
        },
        ^{
            self.textLabel.hidden = NO;
            self.textLabel.text = @"Slowly pan the room with your phone";

            self.button.hidden = NO;
            [self.button setImage:[UIImage imageNamed:@"next"] forState:UIControlStateNormal];
        },
        ^{
            self.textLabel.hidden = NO;
            self.textLabel.text = @"Place your phone on the wall where you want to see the work";

            self.button.hidden = NO;
            [self.button setImage:[UIImage imageNamed:@"next"] forState:UIControlStateNormal];
        },
        ^{
            self.textLabel.hidden = NO;
            self.textLabel.text = @"WALL DETECTED. Push the button to place.";

            self.button.hidden = NO;
            [self.button setImage:[UIImage imageNamed:@"next"] forState:UIControlStateNormal];
        },
        ^{
            [self placeArt];
            self.textLabel.hidden = YES;

            self.button.hidden = NO;
            [self.button setImage:[UIImage imageNamed:@"reset"] forState:UIControlStateNormal];
        }
    ];

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
    self.sceneView.showsStatistics = YES;
    
    // Create a new scene
    SCNScene *scene = [[SCNScene alloc] init];
    self.sceneView.debugOptions = ARSCNDebugOptionShowWorldOrigin | ARSCNDebugOptionShowFeaturePoints;

    self.sceneView.scene = scene;

    // Button
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.tintColor = [UIColor whiteColor];
    button.translatesAutoresizingMaskIntoConstraints = false;

    [button addTarget:self action:@selector(showNextStep) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];

    [self.view addConstraints: @[
        [button.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [button.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant: -30.0],
        [button.heightAnchor constraintEqualToConstant:50.0],
        [button.widthAnchor constraintGreaterThanOrEqualToConstant:50.0]
    ]];
    self.button = button;

    // Text label
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.textColor = UIColor.whiteColor;
    label.font = [UIFont systemFontOfSize:24.0];
    label.translatesAutoresizingMaskIntoConstraints = false;
    label.numberOfLines = 0;
    label.lineBreakMode = NSLineBreakByWordWrapping;

    [self.view addSubview:label];

    [self.view addConstraints: @[
        [label.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:12.0],
        [label.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant: -20.0],
        [label.trailingAnchor constraintEqualToAnchor:button.leadingAnchor constant: 12.0]
    ]];
    self.textLabel = label;

    [self showCurrentStep];
}

- (void)showNextStep {
    self.currentStep += 1;
    if (self.currentStep > OnboardingStepViewing) {
        // Reset
        [self reset];
        self.currentStep = OnboardingStepPlacePhoneOnWall;
    }

    [self showCurrentStep];
}

- (void)showCurrentStep {
    self.steps[self.currentStep]();
}

- (void)placeArt {
    if(!self.isReady) { return; }
    
    CGFloat width = [[[[NSMeasurement alloc] initWithDoubleValue:self.config.size.width
                                                            unit:NSUnitLength.inches]
                      measurementByConvertingToUnit:NSUnitLength.meters]
                     doubleValue];
    ;
    CGFloat height = [[[[NSMeasurement alloc] initWithDoubleValue:self.config.size.height
                                                             unit:NSUnitLength.inches]
                       measurementByConvertingToUnit:NSUnitLength.meters]
                      doubleValue];

    CGFloat length = [[[[NSMeasurement alloc] initWithDoubleValue:self.config.depth
                                                             unit:NSUnitLength.inches]
                       measurementByConvertingToUnit:NSUnitLength.meters]
                      doubleValue];

    SCNBox *box = [SCNBox boxWithWidth:width height:height length:length chamferRadius:0];

    SCNMaterial *blackMaterial = [SCNMaterial material];
    blackMaterial.diffuse.contents = [UIColor blackColor];
    blackMaterial.locksAmbientWithDiffuse = YES;

    SCNMaterial *imageMaterial = [[SCNMaterial alloc] init];
    imageMaterial.diffuse.contents = self.config.image;
    imageMaterial.locksAmbientWithDiffuse = YES;

    // TODO: It seems ARKit glitches out and is inconsistent about which face is the front/back.
    // For now, simply showing the image on both sides gets the job done.
    box.materials =  @[imageMaterial, blackMaterial, imageMaterial, blackMaterial, blackMaterial, blackMaterial];

    simd_float4x4 newLocationSimD = self.sceneView.session.currentFrame.camera.transform;
    SCNVector3 newLocation = SCNVector3Make(newLocationSimD.columns[3].x, newLocationSimD.columns[3].y, newLocationSimD.columns[3].z);

    self.artwork = [SCNNode nodeWithGeometry:box];
    self.artwork.position = newLocation;
    [self.sceneView.scene.rootNode addChildNode:self.artwork];

    // To properly move the art in the real world, we project a vertical plane we can hitTest against later
    // TODO: I wonder if we can generate this automatically later, rather than having a hidden object in our 3D scene

    // There doesn't appear to be a way to flat-out create an infinite plane.
    // 1000x1000 meters seems like a sensible upper bound that doesn't destroy performance
    SCNPlane *infinitePlane = [SCNPlane planeWithWidth:1000 height:1000];
    self.plane = [SCNNode nodeWithGeometry:infinitePlane];
    self.plane.position = newLocation;
    self.plane.hidden = true;

    [self.sceneView.scene.rootNode addChildNode: self.plane];
}

- (void)reset {
    [self.artwork removeFromParentNode];
    self.artwork = nil;

    [self.plane removeFromParentNode];
    self.plane = nil;

    self.currentStep = OnboardingStepPlacePhoneOnWall;
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

#pragma mark - ARSCNViewDelegate

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
            if (self.currentStep == OnboardingStepPlacePhoneOnWall) {
                [self showNextStep];
            }
            break;
        case ARTrackingStateNormal:
            if (self.currentStep == OnboardingStepDetectingPlanes) {
                [self showNextStep];
            }
            break;
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


