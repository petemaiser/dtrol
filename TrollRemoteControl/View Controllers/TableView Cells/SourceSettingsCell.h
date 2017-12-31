//
//  SourceSettingsCell.h
//  TrollRemoteControl
//
//  Created by Pete Maiser on 2/11/17.
//  Copyright © 2017 Pete Maiser. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SourceSettingsCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *sourceLabel;
@property (weak, nonatomic) IBOutlet UITextField *sourceNameTextField;
@property (weak, nonatomic) IBOutlet UISwitch *sourceEnabledSwitch;

@end
