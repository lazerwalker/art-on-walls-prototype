//
//  ARAugmentedRealityConfig.m
//  ArtWallsThing
//
//  Created by Mike Walker on 11/14/17.
//  Copyright © 2017 Orta Therox. All rights reserved.
//

#import "ARAugmentedRealityConfig.h"

@implementation ARAugmentedRealityConfig

- (instancetype)initWithImage:(UIImage *)image
                         size:(CGSize)size {
    self = [super init];

    _image = image;
    _size = size;

    return self;
}
@end
