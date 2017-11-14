//
//  AnimatingUIImageView.h
//  ArtWallsThing
//
//  Created by Michael Walker on 11/14/17.
//  Copyright © 2017 Orta Therox. All rights reserved.
//

@import UIKit;

@interface AnimatingUIImageView: UIImageView
@property (nonatomic) NSTimer *timer;
@property (nonatomic) NSInteger index;

- (void)start;
- (void)stop;
- (void)next;

@end
