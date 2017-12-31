//
//  LinkCell.h
//  TrollRemoteControl
//
//  Created by Pete Maiser on 9/3/16.
//  Copyright © 2016 Pete Maiser. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LinkCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UITextField *hyperlinkNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *hyperlinkAddressTextField;

@end
