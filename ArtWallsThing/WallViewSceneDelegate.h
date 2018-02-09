@import ARKit;
@class ARAugmentedRealityConfig;

@protocol ARInteractive
- (void)tappedScreen:(UITapGestureRecognizer *)gesture;
@end

@interface WallViewSceneDelegate : NSObject <ARSCNViewDelegate, ARInteractive>

- (instancetype)initWithSession:(ARSession *)session config:(ARAugmentedRealityConfig *)config;

- (void)tappedScreen:(UITapGestureRecognizer *)gesture;

@end
