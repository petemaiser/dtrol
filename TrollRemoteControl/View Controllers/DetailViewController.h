//
//  DetailViewController.h
//  TrollRemoteControl
//
//  Created by Pete Maiser on 7/24/16.
//  Copyright © 2016 Pete Maiser. All rights reserved.
//  This program comes with ABSOLUTELY NO WARRANTY.
//  You are welcome to redistribute this software under certain conditions; see the included LICENSE file for details.
//

#import <UIKit/UIKit.h>
@class RemoteServer;
@class RemoteTuner;
@class RemoteZone;
@class MasterViewController;

@interface DetailViewController : UIViewController

@property (weak, nonatomic) MasterViewController *masterViewController;
@property (nonatomic) BOOL existingItem;

@property (strong, nonatomic) RemoteZone *remoteZone;

- (void)resetView;
- (void)refreshViewConfiguration;
- (void)reloadData;

@end

