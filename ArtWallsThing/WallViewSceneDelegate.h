@import ARKit;
@class ARAugmentedRealityConfig;

@protocol ARInteractive
- (void)tappedScreen:(UITapGestureRecognizer *)gesture;
@end

@interface WallViewSceneDelegate : NSObject <ARSCNViewDelegate, ARInteractive, ARSessionObserver>

- (instancetype)initWithSession:(ARSession *)session config:(ARAugmentedRealityConfig *)config scene:(SCNView *)scene;

- (void)tappedScreen:(UITapGestureRecognizer *)gesture;

@end
