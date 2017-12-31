//
//  TunerSettingsCell.h
//  DTrol
//
//  Created by Pete Maiser on 12/6/17.
//  Copyright © 2017 Pete Maiser. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TunerSettingsCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *presetLabel;
@property (weak, nonatomic) IBOutlet UITextField *presetStationText;

@end
