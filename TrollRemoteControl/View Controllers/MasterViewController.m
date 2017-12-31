//
//  MasterViewController.m
//  TrollRemoteControl
//
//  Created by Pete Maiser on 7/24/16.
//  Copyright © 2016 Pete Maiser. All rights reserved.
//  This program comes with ABSOLUTELY NO WARRANTY.
//  You are welcome to redistribute this software under certain conditions; see the included LICENSE file for details.
//

#import "MasterViewController.h"
#import "DetailViewController.h"
#import "ZoneCell.h"
#import "Source.h"
#import "Status.h"
#import "AddServerTableViewController.h"
#import "ZoneSettingsTableViewController.h"
#import "SettingsViewController.h"
#import "LogViewController.h"
#import "Reachability.h"
#import "RemoteServer.h"
#import "RemoteZoneList.h"
#import "RemoteZone.h"
#import "SettingsList.h"
#import "UserPreferences.h"
#import "Log.h"
#import "LogItem.h"

@interface MasterViewController () <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) NSDateFormatter *dateFormatter;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *addServerBarButtonItem;
@property BOOL warnOnNoWiFi;

@end

@implementation MasterViewController


#pragma mark - Managing the View

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    // Configure helpers
    
    self.zoneEditMode = NO;
    
    if (self.dateFormatter == nil) {
        self.dateFormatter = [[NSDateFormatter alloc] init];
        [self.dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        [self.dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
    }
    
    self.warnOnNoWiFi = YES;
    
    // Setup handling for a reachability change
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reloadTable)
                                                 name:kReachabilityChangedNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reloadTable)
                                                 name:StreamNewDataNotificationString
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reloadTable)
                                                 name:StreamClosedNotificationString
                                               object:nil];
    
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    self.navigationItem.title = @"Zones";
    
    [self reloadTable];
    
    // If in split screen mode,
    // and no table items exist then choose what to show as the secondary view
    // else if no row is selected (e.g. at startup), select the first row of the first row (if there is a connection)
    // Also check WiFi is connected
    if (self.splitViewController.collapsed == NO) {
        if ([[[RemoteZoneList sharedList] zones] count] == 0 ) {
            [self showLog:(self)];
        } else if (!self.tableView.indexPathForSelectedRow) {
            if ([[Reachability sharedReachability] currentReachabilityStatus] == ReachableViaWiFi) {
                [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
                [self showDetail:(self)];
            } else {
                [self showWiFiWarning:(self)];
            }
        }
    } else if (self.warnOnNoWiFi &&
               [[Reachability sharedReachability] currentReachabilityStatus] != ReachableViaWiFi)
    {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@""
                                                                       message:@"DTrol requires a WiFi connection, please connect via WiFi."
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* closeAction = [UIAlertAction actionWithTitle:@"Close"
                                                              style:UIAlertActionStyleDefault
                                                            handler:nil];
        if (alert && closeAction) {
            [alert addAction:closeAction];
            [self presentViewController:alert animated:YES completion:nil];
        }
        
        self.warnOnNoWiFi = NO;  // one warning-alert on No WiFi is enough
    }
    
}

- (void)reloadTable
{
    // Keep the same row selected...this requires saving it off and then reselecting it (if not in split-screen)
    NSIndexPath *selectedRowIndexPath = self.tableView.indexPathForSelectedRow;

    [self.tableView reloadData];
    
    if (self.splitViewController.collapsed == NO) {
        
        Reachability *reachability = [Reachability sharedReachability];
        if ([reachability currentReachabilityStatus] == ReachableViaWiFi) {
            if (selectedRowIndexPath) {
                // Reselect the row we saved-off previously
                [self.tableView selectRowAtIndexPath:selectedRowIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
            } else {
                // If no row was known to be selected, select the first row and refresh the detail view
                // UNLESS the Log or Settings view is currently being shown, which is effectively "selecting" log or settings
                UIViewController *secondaryViewController = [[self.splitViewController.viewControllers lastObject] topViewController];
                if ((self != secondaryViewController) &&
                    ( ![secondaryViewController isMemberOfClass:[SettingsViewController class]] ) &&
                    ( ![secondaryViewController isMemberOfClass:[LogViewController class]] ) ) {
                    [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
                    if ([[[RemoteZoneList sharedList] zones] count]) {
                        [self showDetail:(self)];
                    }
                }
            }
        } else {
            [self showWiFiWarning:(self)];
        }
    
    }
    
    [self refreshZoneSetupButtons];
}

- (void)refreshZoneSetupButtons
{
    SettingsList *settings = [SettingsList sharedSettingsList];
    
    if (settings.userPreferences.showZoneSetupButtons) {
        self.navigationItem.leftBarButtonItem = self.editButtonItem;
        if ([[[RemoteZoneList sharedList] zones] count] > 0) {
            self.navigationItem.leftBarButtonItem.enabled = YES;
        } else {
            self.navigationItem.leftBarButtonItem.enabled = NO;
        }
        self.navigationItem.rightBarButtonItem = self.addServerBarButtonItem;
    } else {
        self.navigationItem.leftBarButtonItem = nil;
        self.navigationItem.rightBarButtonItem = nil;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Navigation

- (void)setEditing:(BOOL)editing
          animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    [self.tableView setEditing:editing animated:animated];
}

- (void)showDetail:(id)sender
{
    [self performSegueWithIdentifier:@"showDetail" sender:sender];
}

- (IBAction)showAddServer:(id)sender
{
    if (self.splitViewController.collapsed == YES) {
        [self performSegueWithIdentifier:@"showAddServer" sender:sender];
    }
    else {
        [self performSegueWithIdentifier:@"showAddServerPopover" sender:sender];
    }
}

- (IBAction)showSettings:(id)sender
{
    self.zoneEditMode = NO;
    [self performSegueWithIdentifier:@"showSettings" sender:sender];
}

- (IBAction)showLog:(id)sender
{
    self.zoneEditMode = NO;
    [self performSegueWithIdentifier:@"showLog" sender:sender];
}

- (void)showWiFiWarning:(id)sender
{
    [self performSegueWithIdentifier:@"showWiFiWarning" sender:sender];
}


#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue
                 sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        
        NSArray *zones = [[RemoteZoneList sharedList] zones];
        RemoteZone *zone = zones[indexPath.row];
        
        DetailViewController *vc = (DetailViewController *)[[segue destinationViewController] topViewController];
        
        if (vc) {
            self.selectedDetailController = vc;
            [vc setRemoteZone:zone];
            vc.masterViewController = self;
            vc.existingItem = YES;
        }
        
    }
    else if ( ([[segue identifier] isEqualToString:@"showAddServer"]) ||
              ([[segue identifier] isEqualToString:@"showAddServerPopover"]) ) {
        
        AddServerTableViewController *vc = (AddServerTableViewController *)[[segue destinationViewController] topViewController];
        
        if (vc) {
            vc.masterViewController = self;
        }
        
    }
    else if ([[segue identifier] isEqualToString:@"showSettings"]) {
        
        SettingsViewController *vc = (SettingsViewController *)[[segue destinationViewController] topViewController];
        if (vc) {
            vc.masterViewController = self;
        }
        
    }
    else if ([[segue identifier] isEqualToString:@"showLog"]) {
        
        LogViewController *vc = (LogViewController *)[[segue destinationViewController] topViewController];
        if (vc) {
            vc.masterViewController = self;
        }
        
    }
}


#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[[RemoteZoneList sharedList] zones] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ZoneCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ZoneCell" forIndexPath:indexPath];

    NSArray *zones = [[RemoteZoneList sharedList] zones];
    
    if (zones) {
    
        RemoteZone *zone = zones[indexPath.row];
        
        cell.serverNameShortLabel.text = zone.server.nameShort;
        cell.zoneNameLabel.text = zone.nameLong;
        
        if (zone.server.isConnected) {
        
            [cell.zonePowerStatusSwitch setOn:zone.powerStatus.state];
            
            for (Source *s in zone.sourceList) {
                if ([s.value isEqualToString:zone.sourceStatus.value]) {
                    cell.zoneSourceNameLabel.text = s.name;
                    break;
                }
            }
            
            [cell.zonePowerStatusSwitch setHidden:NO];
            [cell.zoneSourceNameLabel setHidden:NO];
            [cell setUserInteractionEnabled:YES];
            
        } else {
            [cell.zonePowerStatusSwitch setHidden:YES];
            [cell.zoneSourceNameLabel setHidden:YES];
            [cell setUserInteractionEnabled:NO];
        }
        
    }
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        NSArray *zones = [[RemoteZoneList sharedList] zones];
        RemoteZone *zone = zones[indexPath.row];
        
        if (zone)
        {
            // Delete the item from the store and the table
            [[RemoteZoneList sharedList] deleteZone:zone];
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];

            // Refresh views
            if ([[[RemoteZoneList sharedList] zones] count] <= 0) {
                [self setEditing:NO animated:YES];
                [self refreshZoneSetupButtons];
            }
            
            // Log deletion
            NSDate *dateDeleted = [[NSDate alloc] init];
            Log *sharedLog = [Log sharedLog];
            if (sharedLog) {
                [sharedLog addDivider];
                LogItem *logTextLine1 = [LogItem logItemWithText:[NSString stringWithFormat:@"%s:  Zone (%@) \"%@\" deleted: %@"
                                                                  ,getprogname()
                                                                  ,zone.nameShort
                                                                  ,zone.nameLong
                                                                  ,[self.dateFormatter stringFromDate:dateDeleted] ]];
                [sharedLog addItem:logTextLine1];
                [sharedLog addDivider];
            }
 
            // Clean-up the secondary view in a split view controller
            UIViewController *secondaryViewController = [[self.splitViewController.viewControllers lastObject] topViewController];
            if (self != secondaryViewController) {
                if ( [secondaryViewController isMemberOfClass:[DetailViewController class]] )
                {
                    DetailViewController *detailViewController = (DetailViewController *)secondaryViewController;
                    if (zone == detailViewController.remoteZone)
                    {
                        //  We are deleting an item that happens to be showing right now in the Detail View.  Clean up a bit.
                        detailViewController.remoteZone = nil;
                        [detailViewController resetView];
                        
                        // Select another row
                        NSInteger deletedRow = indexPath.row;
                        if (deletedRow > 0) {
                            [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:deletedRow-1 inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
                        } else {
                            [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
                        }
                        
                        // Refresh the detail view
                        if ([[[RemoteZoneList sharedList] zones] count]) {
                            [self showDetail:(self)];
                        } else {
                            [self showLog:(self)];
                        }
                    }
                } else if ( [secondaryViewController isMemberOfClass:[ZoneSettingsTableViewController class]] )
                {
                    ZoneSettingsTableViewController *zstvc = (ZoneSettingsTableViewController *)secondaryViewController;
                    if (zone == zstvc.remoteZone)
                    {
                        //  We are deleting an item that happens to be showing right now in the Detail-ZoneEditing View.  Clean up a bit.
                        [zstvc closeZoneSettings:self];
                        
                        // Select another row
                        NSInteger deletedRow = indexPath.row;
                        if (deletedRow > 0) {
                            [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:deletedRow-1 inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
                        } else {
                            [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
                        }
                        
                        // Refresh the detail view
                        if ([[[RemoteZoneList sharedList] zones] count]) {
                            [self showDetail:(self)];
                        } else {
                            [self showLog:(self)];
                        }
                    
                    }
                } else if ( [secondaryViewController isMemberOfClass:[SettingsViewController class]] )
                {
                } else if ( [secondaryViewController isMemberOfClass:[LogViewController class]] ) {
                    
                    // We just deleted an item; update the log view
                    LogViewController *logViewController = (LogViewController *)secondaryViewController;
                    
                    [logViewController loadMoreLogItems];
                    [logViewController scrollViewToBottom];
                    
                }
            }
        }
        
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }
}

- (void)tableView:(UITableView *)tableView
moveRowAtIndexPath:(NSIndexPath *)fromIndexPath
      toIndexPath:(NSIndexPath *)toIndexPath
{
    [[RemoteZoneList sharedList] moveItemAtIndex:fromIndexPath.row
                                             toIndex:toIndexPath.row];
}

@end
