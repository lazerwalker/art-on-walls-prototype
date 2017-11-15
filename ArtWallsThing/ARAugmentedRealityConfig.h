//
//  ARAugmentedRealityConfig.h
//  ArtWallsThing
//
//  Created by Mike Walker on 11/14/17.
//  Copyright © 2017 Orta Therox. All rights reserved.
//

@import UIKit;

@interface ARAugmentedRealityConfig : NSObject

/** The image to display on the wall */
@property (nonatomic, strong, readonly, nullable) UIImage *image;

/** The real-world size of the artwork, in inches */
@property (nonatomic, assign, readonly) CGSize size;

- (nonnull instancetype)initWithImage:(nonnull UIImage *)image
                                 size:(CGSize)size;

@end
