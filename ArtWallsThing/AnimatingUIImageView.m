//
//  AnimatingUIImageView.m
//  ArtWallsThing
//
//  Created by Michael Walker on 11/14/17.
//  Copyright © 2017 Orta Therox. All rights reserved.
//

#import "AnimatingUIImageView.h"

@implementation AnimatingUIImageView

- (void)start
{
    if (self.timer) { return; }
    _index = 0;
    _timer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                              target:self
                                            selector:@selector(next)
                                            userInfo:nil
                                             repeats:YES];
}

- (void)next
{
    if(self.index == 3) { self.index = 0; }
    self.index++;
    NSString *imageName = [NSString stringWithFormat:@"move%@.png", @(self.index)];
    [self setImage:[UIImage imageNamed:imageName]];
}

- (void)stop
{
    [self.timer invalidate];
    self.timer = nil;
}



@end
