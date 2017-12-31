//
//  AppDelegate.m
//  TrollRemoteControl
//
//  Created by Pete Maiser on 7/24/16.
//  Copyright © 2016 Pete Maiser. All rights reserved.
//  This program comes with ABSOLUTELY NO WARRANTY.
//  You are welcome to redistribute this software under certain conditions; see the included LICENSE file for details.
//

#import "AppDelegate.h"
#import "DetailViewController.h"
#import "SettingsList.h"
#import "RemoteServerList.h"
#import "RemoteTunerList.h"
#import "RemoteZoneList.h"
#import "Reachability.h"
#import "RemoteServer.h"
#import "Log.h"
#import "LogItem.h"

@interface AppDelegate () <UISplitViewControllerDelegate>

@property (nonatomic, copy) NSString *logFile;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Configure helpers
    self.logFile = @"";
    if (self.dateFormatter == nil) {
        self.dateFormatter = [[NSDateFormatter alloc] init];
        [self.dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        [self.dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
    }
    
    // Startup View Controllers
    UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
    splitViewController.preferredDisplayMode = UISplitViewControllerDisplayModeAllVisible;
    splitViewController.delegate = self;
    
    // Startup Servers
    [self startupServers];
    
    // Start Reachability Notifier
    Reachability *reachability = [Reachability sharedReachability];
    [reachability startNotifier];
    
    return YES;
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Close the server streams.  Also, if a server has no remote zones using it, clean it up,
    // and also clean-up any tuners are tied to that server - no zones, then no need for a server or a tuner
    NSArray *servers = [[RemoteServerList sharedList] servers];
    for (RemoteServer *server in servers) {
        [server closeStreams];
        
        if (![[RemoteZoneList sharedList] validateServer:server]) {
            [[RemoteTunerList sharedList] deteleTunersWithServer:server];
            [[RemoteServerList sharedList] deleteServer:server];
        }
    }
    
    // Archive everything
    
    BOOL success = [[SettingsList sharedSettingsList] saveSettings];
    if (!success) {
        [self logString:@"ERROR:  Attempt to save Settings failed"];
    }
   
    success = [[RemoteServerList sharedList] saveServers];
    if (!success) {
        [self logString:@"ERROR:  Attempt to save Servers failed"];
    }

    success = [[RemoteTunerList sharedList] saveTuners];
    if (!success) {
        [self logString:@"ERROR:  Attempt to save Tuners failed"];
    }
    
    success = [[RemoteZoneList sharedList] saveZones];
    if (!success) {
        [self logString:@"ERROR:  Attempt to save Zones failed"];
    }

    success = [[Log sharedLog] saveLog];
    if (!success) {
        [self logString:@"ERROR:  Attempt to save Log failed"];
    }
    
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    [self startupServers];
}


#pragma mark - Split view

- (BOOL)splitViewController:(UISplitViewController *)splitViewController collapseSecondaryViewController:(UIViewController *)secondaryViewController ontoPrimaryViewController:(UIViewController *)primaryViewController {
    if ([secondaryViewController isKindOfClass:[UINavigationController class]] && [[(UINavigationController *)secondaryViewController topViewController] isKindOfClass:[DetailViewController class]] && ([(DetailViewController *)[(UINavigationController *)secondaryViewController topViewController] remoteZone] == nil)) {
        // Return YES to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
        return YES;
    } else {
        return NO;
    }
}


#pragma mark - Helpers

- (void)startupServers
{
    NSDate *dateStarted = [[NSDate alloc] init];
    
    Log *sharedLog = [Log sharedLog];
    if (sharedLog) {
        [sharedLog addDivider];
    }
    
    // Reopen the servers, if they need it, plus the other model objects (they probably do need to be opened)
    NSArray *servers = [[RemoteServerList sharedList] servers];
    [self logString:[NSString stringWithFormat:@"%s:  %lu Servers loaded %@", getprogname(), (unsigned long)[servers count], [self.dateFormatter stringFromDate:dateStarted]]];
    
    NSArray *tuners = [[RemoteTunerList sharedList] tuners];
    [self logString:[NSString stringWithFormat:@"%s:  %lu Tuners loaded %@", getprogname(), (unsigned long)[tuners count], [self.dateFormatter stringFromDate:dateStarted]]];
    
    NSArray *zones = [[RemoteZoneList sharedList] zones];
    [self logString:[NSString stringWithFormat:@"%s:  %lu Zones loaded %@", getprogname(), (unsigned long)[zones count], [self.dateFormatter stringFromDate:dateStarted]]];
    
    Reachability *reachability = [Reachability sharedReachability];
    if ([reachability currentReachabilityStatus] == ReachableViaWiFi) {
        
        for (RemoteServer *server in servers) {
            
            if ([server streamsNeedOpen]) {
                [server openStreams];
            }
        }
    } else {
        for (RemoteServer *server in servers) {
            server.isConnected = NO;
        }
        
    }
}

- (void)logString:(NSString *)str
{
    if (!self.logFile) {
        
        NSLog(@"%@", str);
        
    } else if ([self.logFile isEqualToString:@""]) {
        
        Log *sharedLog = [Log sharedLog];
        if (sharedLog) {
            LogItem *logTextLine1 = [LogItem logItemWithText:str];
            [sharedLog addItem:logTextLine1];
        }
        
    } else {
        
        NSString *programName = [NSString stringWithUTF8String:getprogname()];
        
        NSDate *date = [NSDate date];
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
        
        NSString *formattedString = [NSString stringWithFormat:@"%@ %@: %@\n", programName ,[dateFormatter stringFromDate:date], str];
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if(![fileManager fileExistsAtPath:self.logFile])
        {
            [formattedString writeToFile:self.logFile
                              atomically:YES
                                encoding:NSUTF8StringEncoding
                                   error:nil];
        }
        else
        {
            NSFileHandle *myHandle = [NSFileHandle fileHandleForWritingAtPath:self.logFile];
            [myHandle seekToEndOfFile];
            [myHandle writeData:[formattedString dataUsingEncoding:NSUTF8StringEncoding]];
        }
        
    }
}

@end
