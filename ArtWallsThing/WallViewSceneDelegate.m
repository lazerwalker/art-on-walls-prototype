
#import "WallViewSceneDelegate.h"
@import OpenGLES;
#import "SCNArtworkNode.h"

@interface WallViewSceneDelegate()
@property ARSession *session;
@property ARAugmentedRealityConfig *config;
@property NSArray<SCNNode *> *detectedPlanes;
@property NSArray<SCNNode *> *invisibleWalls;
@end

NSInteger wallHeight = 5;

@implementation WallViewSceneDelegate

- (instancetype)initWithSession:(ARSession *)session config:(ARAugmentedRealityConfig *)config
{
    self = [super init];
    _session = session;
    _config = config;
    _invisibleWalls = @[];
    _detectedPlanes = @[];
    return self;
}

- (void)tappedScreen:(UITapGestureRecognizer *)gesture
{
    if (![gesture.view isKindOfClass:SCNView.class]) {
        NSLog(@"Tap wasn't on a SCNView");
        return;
    }

    SCNView *sceneView = (id)gesture.view;

    CGPoint point = [gesture locationOfTouch:0 inView:sceneView];

    NSDictionary *options = @{
        SCNHitTestIgnoreHiddenNodesKey: @NO,
        SCNHitTestFirstFoundOnlyKey: @YES,
        SCNHitTestOptionSearchMode: @(SCNHitTestSearchModeAll)
    };

    NSArray <SCNHitTestResult *> *results = [sceneView hitTest:point options: options];
    for (SCNHitTestResult *result in results) {
        NSLog(@"-- %@", result.node);

        if ([self.invisibleWalls containsObject:result.node] || [self.detectedPlanes containsObject:result.node] ) {
//            self.artwork.position = result.worldCoordinates;

            SCNBox *box = [SCNArtworkNode nodeWithConfig:self.config];

//            simd_float4x4 newLocationSimD = sceneView.session.currentFrame.camera.transform;
//            SCNVector3 newLocation = SCNVector3Make(newLocationSimD.columns[3].x, newLocationSimD.columns[3].y, newLocationSimD.columns[3].z);

            SCNNode *artwork = [SCNNode nodeWithGeometry:box];
            artwork.position = result.localCoordinates;
            [result.node addChildNode:artwork];
        } else {
            NSLog(@"Childs %@", result.node.childNodes);
        }
    }
}

//- (void)hitTestForWall:(ARFrame *)frame devicePoint:(CGPoint)point
//{
//
//    [frame hitTest:point types:ARHitTestResultTypeEstimatedVerticalPlane];
//}

- (void)renderer:(id<SCNSceneRenderer>)renderer willRenderScene:(SCNScene *)scene atTime:(NSTimeInterval)time
{
//    glLineWidth(20);
}

- (void)renderer:(id<SCNSceneRenderer>)renderer didUpdateNode:(SCNNode *)node forAnchor:(ARAnchor *)anchor
{
    // Used to update and re-align vertical planes as ARKit sends new updates for the positioning
    if(!anchor) { return; }
    if(![anchor isKindOfClass:ARPlaneAnchor.class]) { return; }

    ARPlaneAnchor *planeAnchor = (id)anchor;

    for (SCNNode *planeNode in node.childNodes) {
        SCNPlane *plane = (id)planeNode.geometry;

        if([self.detectedPlanes containsObject:planeNode]) {
            plane.width = planeAnchor.extent.x;
            plane.height = planeAnchor.extent.z;
            planeNode.position = SCNVector3FromFloat3(planeAnchor.center);
        }

        if([self.invisibleWalls containsObject:planeNode]) {
            planeNode.position = SCNVector3FromFloat3(planeAnchor.center);
        }

    }

}

- (void)renderer:(id <SCNSceneRenderer>)renderer didAddNode:(SCNNode *)node forAnchor:(ARAnchor *)anchor;
{
    node.name = @"OK";

    // Only handle adding plane nodes
    if(!anchor) { return; }
    if(![anchor isKindOfClass:ARPlaneAnchor.class]) { return; }


    ARPlaneAnchor *planeAnchor = (id)anchor;

    // Create an anchor node, which can get moved around as we become more sure of where the
    // plane actually is.

    SCNNode *planeNode = [self debugRedNodeForPlaneAnchor:planeAnchor];
    [node addChildNode:planeNode];

    SCNNode *wallNode = [self debugWallNodeForPlaneAnchor:planeAnchor];
    [node addChildNode:wallNode];

    self.invisibleWalls = [self.invisibleWalls arrayByAddingObject:wallNode];
    self.detectedPlanes = [self.detectedPlanes arrayByAddingObject:planeNode];

//    matrix_float4x4 translation = matrix_identity_float4x4;
//    translation.columns[3][2] = -0.1; // Translate 10 cm away plane
//    hittablePlane.simdTransform = matrix_multiply(self.session.currentFrame.camera.transform, translation);

//    SCNNode *floorNode = [self debugFloorNodeForPointCloud:self.session.currentFrame.rawFeaturePoints planeAnchor:planeAnchor];
//    [node addChildNode:floorNode];
//
//    SCNNode *roofNode = [self debugRoofNodeForPointCloud:self.session.currentFrame.rawFeaturePoints planeAnchor:planeAnchor];
//    [node addChildNode:roofNode];
}

- (SCNNode *)debugRedNodeForPlaneAnchor:(ARPlaneAnchor *)planeAnchor
{
    SCNPlane *plane = [SCNPlane planeWithWidth:planeAnchor.extent.x height:planeAnchor.extent.z];
    plane.firstMaterial.diffuse.contents = [[UIColor whiteColor] colorWithAlphaComponent:0.3];

    SCNNode *planeNode = [SCNNode nodeWithGeometry:plane];
    planeNode.position = SCNVector3Make(planeAnchor.center.x, planeAnchor.center.y, planeAnchor.center.z);  //
    planeNode.name = @"Detected Area";

    planeNode.eulerAngles = SCNVector3Make(-M_PI_2, 0, 0);
    return planeNode;
}


- (SCNNode *)debugWallNodeForPlaneAnchor:(ARPlaneAnchor *)planeAnchor
{
    SCNPlane *infinitePlane = [SCNPlane planeWithWidth:32 height:wallHeight];
    infinitePlane.materials.firstObject.diffuse.contents = [UIColor clearColor];

    SCNNode *hittablePlane = [SCNNode nodeWithGeometry:infinitePlane];

    SCNVector3 wallCenter = SCNVector3FromFloat3(planeAnchor.center);
    wallCenter.y -= wallHeight * 0.8;
    wallCenter.x -= 0.1;
    hittablePlane.position = wallCenter;
    hittablePlane.eulerAngles = SCNVector3Make(-M_PI_2, 0, 0);

    // Hidden area
//    hittablePlane.hidden = true;

    return hittablePlane;
}

- (UIEdgeInsets)getReasonableTopBottomPointsInPointCloud:(ARPointCloud *)cloud
{
    const vector_float3 *points = cloud.points;

    // 0 in this case is the world "starting point", so
    // it's very likely to be _under_ this as people
    // will be holding their phone above the floor
    float lowest = 0, highest = 0;

    for (int i = 0; i < cloud.count; i++) {
        const float z = points[i][1];
        printf("> %f\n", z);

        if(isnan(z) || isinf(z)) { continue; }

        // Lowest Check
        if (z < -0.01 && -1.5 < z) {
            const float roundZ = floorf(z * 10000) / 10000;

            if (lowest > roundZ) {
                lowest = roundZ;
            }
        }
        // Highest Check
        if (z > -0.01 && 1.5 > z) {
            const float roundZ = floorf(z * 10000) / 10000;
            printf("high? %f\n", roundZ);

            if (highest < roundZ) {
                highest = roundZ;
            }
        }
    }
    printf("\nFound { top: %f, bottom: %f}\n", highest, lowest);
    return UIEdgeInsetsMake(highest, 0, lowest, 0);
}

- (SCNNode *)debugFloorNodeForPointCloud:(ARPointCloud *)cloud planeAnchor:(ARPlaneAnchor *)planeAnchor
{
    const float lowest = [self getReasonableTopBottomPointsInPointCloud:cloud].bottom;

    SCNPlane *plane = [SCNPlane planeWithWidth:5 height:5];
    plane.firstMaterial.diffuse.contents = [[UIColor yellowColor] colorWithAlphaComponent:0.5];
    plane.firstMaterial.doubleSided = YES;

    SCNNode *planeNode = [SCNNode nodeWithGeometry:plane];
    planeNode.position = SCNVector3Make(planeAnchor.center.x, planeAnchor.center.y, -lowest);

    planeNode.eulerAngles = SCNVector3Make(0,0, M_PI_2);
    return planeNode;
}


- (SCNNode *)debugRoofNodeForPointCloud:(ARPointCloud *)cloud planeAnchor:(ARPlaneAnchor *)planeAnchor
{
    const float highest = [self getReasonableTopBottomPointsInPointCloud:cloud].top;

    SCNPlane *plane = [SCNPlane planeWithWidth:5 height:5];
    plane.materials.firstObject.diffuse.contents = [[UIColor orangeColor] colorWithAlphaComponent:0.5];
    plane.firstMaterial.doubleSided = YES;

    SCNNode *planeNode = [SCNNode nodeWithGeometry:plane];
    planeNode.position = SCNVector3Make(planeAnchor.center.x, planeAnchor.center.y, highest);

    planeNode.eulerAngles = SCNVector3Make(0,0, M_PI_2);
    return planeNode;
}




    // Find index of the maximum repeating element
//    float  min = arr[0], result = 0;
//    for (int i = 1; i < n; i++) {
//        if (arr[i] < min) {
//            max = arr[i];
//            result = i;
//        }
//    }


//

//    SCNPlane *plane = [SCNPlane planeWithWidth:planeAnchor.extent.x height:planeAnchor.extent.z];
//    plane.materials.firstObject.diffuse.contents = [[UIColor greenColor] colorWithAlphaComponent:0.3];
//
//    SCNNode *planeNode = [SCNNode nodeWithGeometry:plane];
//    planeNode.position = SCNVector3Make(planeAnchor.center.x, planeAnchor.center.y, planeAnchor.center.z);  //
//
//    planeNode.eulerAngles = SCNVector3Make(0, -M_PI_2, 0);
//    return planeNode;
//}


// https://stackoverflow.com/questions/20778681/drawing-dashed-line-in-sprite-kit-using-skshapenode-and-cgpath#24406320
//
- (SCNNode *)openGLLineForPlaneAnchor:(ARPlaneAnchor *)planeAnchor
{
    CGFloat halfWidth =  planeAnchor.extent.x / 2;
    CGFloat halfHeight =  planeAnchor.extent.z / 2;

//    CGPoint center = CGPointMake(planeAnchor.center.x, planeAnchor.center.y);
//
//    CGPoint point1 = CGPointMake(-halfWidth,-halfHeight); // BL
//    CGPoint point2 = CGPointMake(-halfWidth, halfHeight); // TL
//    CGPoint point3 = CGPointMake(halfWidth,  halfHeight); // TR
//    CGPoint point4 = CGPointMake(halfWidth, -halfHeight); // BR

//
//    SCNPlane *plane = [SCNPlane planeWithWidth:planeAnchor.extent.x height:planeAnchor.extent.z];
//    plane.materials.firstObject.diffuse.contents = [UIColor redColor];
//
//
//
//    SCNNode *planeNode = [SCNNode nodeWithGeometry:plane];
//    planeNode.position = SCNVector3Make(planeAnchor.center.x, planeAnchor.center.y, planeAnchor.center.z);  //
//
//    planeNode.eulerAngles = SCNVector3Make(-M_PI_2, 0, 0);

//    SCNNode *planeNode = [SCNNode nodeWithGeometry:plane];
//    planeNode.position = SCNVector3Make(planeAnchor.center.x, planeAnchor.center.y, planeAnchor.center.z);  //

//    UIBezierPath *path=[UIBezierPath bezierPath];
//

//    [path moveToPoint:point1];
//    [path addLineToPoint:point2];
//    [path addLineToPoint:point3];
//    [path addLineToPoint:point4];
//    [path addLineToPoint:point1];
//
//    CGFloat pattern[2];
//    pattern[0] = 10.0;
//    pattern[1] = 10.0;
//
//    CGPathRef dashed = CGPathCreateCopyByDashingPath([path CGPath], NULL, 0, pattern, 2);
//
//    SKShapeNode *shapeNode = [SKShapeNode shapeNodeWithPath:path.CGPath];
//    SK3DNode *mapperNode = []
//    SCNPlane *plane = [SCNPlane planeWithWidth:planeAnchor.extent.x height:planeAnchor.extent.z];
//    plane.materials = @[shapeNode];
//
//    SCNNode *planeNode = [SCNNode nodeWithGeometry:plane];
//    planeNode.eulerAngles = SCNVector3Make(-M_PI_2, 0, 0);
//    planeNode.position = SCNVector3Make(planeAnchor.center.x, planeAnchor.center.y, planeAnchor.center.z);
//
//    CGPathRelease(dashed);
//    return plane;


    SCNVector3 spoint1 = SCNVector3Make(-halfWidth,-halfHeight, 0); // BL
    SCNVector3 spoint2 = SCNVector3Make(-halfWidth, halfHeight, 0); // TL
    SCNVector3 spoint3 = SCNVector3Make(halfWidth,  halfHeight, 0); // TR
    SCNVector3 spoint4 = SCNVector3Make(halfWidth, -halfHeight, 0); // BR

    SCNNode *root = [SCNNode node];
    root.eulerAngles = SCNVector3Make(-M_PI_2, 0, 0);
    root.position = SCNVector3Make(planeAnchor.center.x, planeAnchor.center.y, planeAnchor.center.z);

    SCNNode *topline = [self lineFrom:spoint1 toVector:spoint2];
    SCNNode *leftline = [self lineFrom:spoint2 toVector:spoint3];
    SCNNode *bottomline = [self lineFrom:spoint3 toVector:spoint4];
    SCNNode *rightline = [self lineFrom:spoint4 toVector:spoint1];

    [root addChildNode:topline];
    [root addChildNode:leftline];
    [root addChildNode:bottomline];
    [root addChildNode:rightline];
    return root;
}


- (SCNNode *)lineFrom:(SCNVector3)vector1 toVector:(SCNVector3)vector2
{
    int indices[] = {0, 1};
    SCNVector3 vertices[] = {vector1, vector2};
    SCNGeometrySource *vertexSource = [SCNGeometrySource geometrySourceWithVertices:vertices count:2];

    NSData *indexData = [NSData dataWithBytes:indices length:sizeof(indices)];

    SCNGeometryElement *element = [SCNGeometryElement geometryElementWithData:indexData
                                                                primitiveType:SCNGeometryPrimitiveTypeLine
                                                               primitiveCount:1
                                                                bytesPerIndex:sizeof(int)];

    SCNGeometry *line = [SCNGeometry geometryWithSources:@[vertexSource]
                                                elements:@[element]];

    return [SCNNode nodeWithGeometry:line];
}

@end


// https://www.geeksforgeeks.org/find-the-maximum-repeating-number-in-ok-time/

//// Returns maximum repeating element in arr[0..n-1].
//// The array elements are in range from 0 to k-1
//int maxRepeating(float* arr, int n, int k)
//{
//    // Iterate though input array, for every element
//    // arr[i], increment arr[arr[i]%k] by k
//    for (int i = 0; i< n; i++)
//        arr[arr[i]%k] += k;
//
//    // Find index of the maximum repeating element
//    int max = arr[0], result = 0;
//    for (int i = 1; i < n; i++)
//    {
//        if (arr[i] > max)
//        {
//            max = arr[i];
//            result = i;
//        }
//    }
//
//    /* Uncomment this code to get the original array back
//     for (int i = 0; i< n; i++)
//     arr[i] = arr[i]%k; */
//
//    // Return index of the maximum element
//    return result;
//}

