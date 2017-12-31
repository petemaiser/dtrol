//
//  SourceSettingsViewController.h
//  TrollRemoteControl
//
//  Created by Pete Maiser on 2/11/17.
//  Copyright © 2017 Pete Maiser. All rights reserved.
//

#import <UIKit/UIKit.h>
@class DetailViewController;
@class MasterViewController;
@class RemoteZone;

@interface SourceSettingsViewController : UIViewController
@property (weak, nonatomic) DetailViewController *detailViewController;
@property (weak, nonatomic) MasterViewController *masterViewController;
@property (strong, nonatomic) RemoteZone *remoteZone;
@end
