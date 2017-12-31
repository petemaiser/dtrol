//
//  ZoneCell.h
//  TrollRemoteControl
//
//  Created by Pete Maiser on 8/19/16.
//  Copyright © 2016 Pete Maiser. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ZoneCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *serverNameShortLabel;
@property (weak, nonatomic) IBOutlet UILabel *zoneNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *zoneSourceNameLabel;
@property (weak, nonatomic) IBOutlet UISwitch *zonePowerStatusSwitch;

@end
