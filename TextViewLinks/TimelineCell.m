//
//  TimelineCell.m
//  TextViewLinks
//
//  Created by kishikawa katsumi on 2013/06/05.
//  Copyright (c) 2013 kishikawa katsumi. All rights reserved.
//

#import "TimelineCell.h"

@implementation TimelineCell

- (void)awakeFromNib
{
    self.iconImageView.layer.cornerRadius = 4.0f;
    self.iconImageView.layer.masksToBounds = YES;
}

@end
