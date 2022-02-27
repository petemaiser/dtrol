//
//  ZoneSettingsTableViewController.h
//  TrollRemoteControl
//
//  Created by Pete Maiser on 2/16/17.
//  Copyright © 2017 Pete Maiser. All rights reserved.
//

#import <UIKit/UIKit.h>
@class DetailViewController;
@class MasterViewController;
@class RemoteZone;
@class RemoteTuner;

@interface ZoneSettingsTableViewController : UITableViewController

@property (weak, nonatomic) DetailViewController *detailViewController;
@property (weak, nonatomic) MasterViewController *masterViewController;
@property (strong, nonatomic) RemoteZone *remoteZone;
@property (strong, nonatomic) RemoteTuner *remoteTuner;

- (void)closeZoneSettings:(id)sender;

@end

#define volumeMin -80
#define volumeMax 20
#define volumeMinMaxRange 60
