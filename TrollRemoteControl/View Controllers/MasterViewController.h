//
//  MasterViewController.h
//  TrollRemoteControl
//
//  Created by Pete Maiser on 7/24/16.
//  Copyright © 2016 Pete Maiser. All rights reserved.
//  This program comes with ABSOLUTELY NO WARRANTY.
//  You are welcome to redistribute this software under certain conditions; see the included LICENSE file for details.
//

#import <UIKit/UIKit.h>
@class DetailViewController;

@interface MasterViewController : UIViewController 

@property (weak, nonatomic) DetailViewController *selectedDetailController;
@property BOOL zoneEditMode;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIToolbar *bottomToolbar;

- (void)reloadTable;
- (void)refreshZoneSetupButtons;
- (void)showLog:(id)sender;

@end

