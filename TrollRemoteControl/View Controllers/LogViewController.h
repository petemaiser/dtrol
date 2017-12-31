//
//  LogViewController.h
//  GameCalc, TrollRemoteControl
//
//  Created by Pete Maiser on 3/27/16.
//  Copyright © 2016 Pete Maiser. All rights reserved.
//

#import <UIKit/UIKit.h>
@class MasterViewController;

@interface LogViewController : UIViewController

@property (weak, nonatomic) MasterViewController *masterViewController;

- (void)loadLogItems;
- (void)scrollViewToBottom;
- (void)loadMoreLogItems;

@end
