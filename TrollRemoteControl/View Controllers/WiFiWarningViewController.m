//
//  WiFiWarningViewController.m
//  TrollRemoteControl
//
//  Created by Pete Maiser on 9/29/16.
//  Copyright © 2016 Pete Maiser. All rights reserved.
//

#import "WiFiWarningViewController.h"
#import "Log.h"
#import "LogItem.h"

@interface WiFiWarningViewController ()

@end

@implementation WiFiWarningViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    Log *sharedLog = [Log sharedLog];
    if (sharedLog) {
        [sharedLog addDivider];
        LogItem *logTextLine = [LogItem logItemWithText:[NSString stringWithFormat:@"Please Connect via WiFi"]];
        
        
        [sharedLog addItem:logTextLine];
        [sharedLog addDivider];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
