//
//  AddServerTableViewController.h
//  TrollRemoteControl
//
//  Created by Pete Maiser on 2/18/17.
//  Copyright © 2017 Pete Maiser. All rights reserved.
//

#import <UIKit/UIKit.h>
@class RemoteServer;
@class MasterViewController;

@interface AddServerTableViewController : UITableViewController

@property (weak, nonatomic) MasterViewController *masterViewController;

- (void)displayFeedbackTextString:(NSString *)string;

@end

