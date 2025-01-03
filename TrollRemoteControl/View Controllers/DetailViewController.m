//
//  DetailViewController.m
//  TrollRemoteControl
//
//  Created by Pete Maiser on 7/24/16.
//  Copyright © 2016 Pete Maiser. All rights reserved.
//  This program comes with ABSOLUTELY NO WARRANTY.
//  You are welcome to redistribute this software under certain conditions; see the included LICENSE file for details.
//

#import "MasterViewController.h"
#import "DetailViewController.h"
#import "ZoneSettingsTableViewController.h"
#import "ServerConfigHelper.h"
#import "RemoteServerList.h"
#import "RemoteTunerList.h"
#import "RemoteZoneList.h"
#import "SettingsList.h"
#import "RemoteServer.h"
#import "Reachability.h"
#import "RemoteComponent.h"
#import "RemoteTuner.h"
#import "RemoteZone.h"
#import "Source.h"
#import "Status.h"
#import "Command.h"
#import "UserPreferences.h"
#import "Hyperlink.h"
#import "Log.h"
#import "LogItem.h"

@interface DetailViewController () < UINavigationControllerDelegate, UIPickerViewDelegate >

@property (strong, nonatomic) RemoteServer *remoteServer;
@property (strong, nonatomic) RemoteTuner *remoteTuner;

@property (strong, nonatomic) NSDateFormatter *dateFormatter;
@property (weak, nonatomic) UserPreferences *userPreferences;

@property (weak) IBOutlet UITextField *zoneNameTextField;
@property (weak, nonatomic) IBOutlet UISwitch *powerSwitch;
@property (nonatomic) BOOL isChangingFromRecordToZone;
@property (weak, nonatomic) IBOutlet UISwitch *muteSwitch;

@property (weak, nonatomic) IBOutlet UIPickerView *sourcePicker;
@property (nonatomic) NSArray *sourceList;
@property (weak, nonatomic) IBOutlet UIPickerView *volumePicker;
@property (nonatomic) NSMutableArray *volumeStrings;
@property (weak, nonatomic) IBOutlet UIPickerView *linkPicker;
@property (nonatomic) NSArray *hyperlinks;

@property (weak, nonatomic) IBOutlet UIButton *linkButton;
@property (weak) IBOutlet UITextField *frequencyTextField;
@property (weak) IBOutlet UITextField *presetTextField;
@property (weak, nonatomic) IBOutlet UIButton *presetDownButton;
@property (weak, nonatomic) IBOutlet UIButton *presetUpButton;

@end

@implementation DetailViewController

#pragma mark - Managing the Detail Item

- (void)viewDidLoad
{
    [super viewDidLoad];
  
    if (self.masterViewController.zoneEditMode == YES) {
        [self showSettings:self];
    } else {
    
        // Configure helpers
        if (self.dateFormatter == nil) {
            self.dateFormatter = [[NSDateFormatter alloc] init];
            [self.dateFormatter setDateStyle:NSDateFormatterMediumStyle];
            [self.dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
        }
        
        // Set the server
        self.remoteServer = self.remoteZone.server;
        
        // Set the tuner
        if (self.remoteZone.tunerOverrideZoneUUID) {
            RemoteZone *tunerOverrideZone = [[RemoteZoneList sharedList] getZoneWithZoneUUID:self.remoteZone.tunerOverrideZoneUUID];
            self.remoteTuner = [[RemoteTunerList sharedList] getTunerWithServerUUID:tunerOverrideZone.serverUUID];
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(reloadTunerData)
                                                         name:StreamNewDataNotificationString
                                                       object:tunerOverrideZone.server];
        } else {
            self.remoteTuner = [[RemoteTunerList sharedList] getTunerWithServerUUID:self.remoteZone.serverUUID];
        }
        
        self.isChangingFromRecordToZone = NO;
        
        self.volumeStrings = nil;
        
        if (self.remoteServer) {
            self.sourceList = self.remoteZone.sourceList;
        } else {
            Command *c = [[Command alloc] initWithVariable:@""
                                        parameterPrefix:@""
                                              parameter:@"0"];
            Source *s = [[Source alloc] initWithName:@"Source"
                                            variable:@"-"
                                               value:@"0"
                                       sourceCommand:c
                                             enabled:@"Yes"];
            self.sourceList = [[NSArray alloc] initWithObjects:s,nil];
        }
        
        SettingsList *settings = [SettingsList sharedSettingsList];
        if ([settings.hyperlinks count] > 0) {
            self.hyperlinks = [[NSArray alloc] initWithArray:settings.hyperlinks];
        } else {
            self.hyperlinks = [[NSArray alloc] init];
        }
        self.userPreferences = settings.userPreferences;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(reloadData)
                                                     name:StreamNewDataNotificationString
                                                   object:self.remoteServer];
        
        if (self.masterViewController.splitViewController.collapsed == YES) {
            
            // Setup handling for a reachability change on the iPhone (iPad handled in the mvc)
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(reachabilityChanged:)
                                                         name:kReachabilityChangedNotification
                                                       object:nil];
            
        }
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Configure View
    if (!self.masterViewController) {
        
        // No MVC is setup, so we must have arrived here from a split view vs being called via the segue.
        // This would happen at app startup.  There is nothing to show.
        
        self.navigationItem.title = [NSString stringWithFormat:@""];
        if (self.splitViewController.displayMode == UISplitViewControllerDisplayModeOneBesideSecondary ) {
            self.navigationItem.leftBarButtonItem = nil;
        }
        self.navigationItem.rightBarButtonItem = nil;
        
    } else if (!self.existingItem) {
        
        // This must be a new item.  This view does not support this situation
        
    } else if (self.remoteZone) {
        
        // We are using the view for accessing an existing item
        
        self.navigationItem.title = self.remoteZone.nameShort;
        
        // Setup the Zone Settings Button - unless that has been disabled.
        if (self.userPreferences.showZoneSetupButtons) {
        
            UIBarButtonItem *settingsButton;
            if (self.masterViewController.splitViewController.collapsed == YES) {
                UIImage *gearImage = [[UIImage imageNamed:@"bluegear32.edited.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
                settingsButton = [[UIBarButtonItem alloc] initWithImage:gearImage
                                                                  style:UIBarButtonItemStylePlain
                                                                 target:self
                                                                 action:@selector(showSettings:)];
            } else {
                settingsButton = [[UIBarButtonItem alloc] initWithTitle:@"Zone Settings"
                                                                  style:UIBarButtonItemStylePlain
                                                                 target:self
                                                                 action:@selector(showSettings:)];
            }
            self.navigationItem.rightBarButtonItem = settingsButton;
            
        }
        
        // FUTURE enable tuner controls to be hidden https://github.com/petemaiser/dtrol/issues/9
        // FUTURE Hide tuner controls if tuner source is disabled
//        if (!self.remoteZone.tunerOverrideZoneUUID)
//            and the remoteServerZone Source with
//            self.remoteZone.server.tunerSourceValue
//            is
//            enabled == false
//            then hide the Tuner fields
           
        if (self.remoteZone.muteStatus)     // Hide indicator if it is not relevant
        {
            self.muteSwitch.hidden = NO;
        } else {
            self.muteSwitch.hidden = YES;
        }
        
        self.presetDownButton.backgroundColor = [UIColor colorWithRed:.6 green:.6 blue:.6 alpha:1];
    }
    
    [self refreshViewConfiguration];
    
    [self reloadData];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // Clear the first responder
    [self.view endEditing:YES];
    
}

- (void)reachabilityChanged:(NSNotification *)note
{
    Reachability* reachability = [note object];
    NSParameterAssert([reachability isKindOfClass:[Reachability class]]);
    
    if ([reachability currentReachabilityStatus] != ReachableViaWiFi) {
        
        Log *sharedLog = [Log sharedLog];
        if (sharedLog) {
            [sharedLog addDivider];
            LogItem *logTextLine = [LogItem logItemWithText:[NSString stringWithFormat:@"Please Connect via WiFi"]];
            
            
            [sharedLog addItem:logTextLine];
            [sharedLog addDivider];
        }
        
        [self.masterViewController.navigationController popToRootViewControllerAnimated:YES];
        
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Navigation

- (void)showSettings:(id)sender
{
    [self performSegueWithIdentifier:@"showZoneSettings" sender:sender];
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue
                 sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showZoneSettings"]) {
        
        ZoneSettingsTableViewController *vc = (ZoneSettingsTableViewController *)[[segue destinationViewController] topViewController];
        
        if (vc) {
            vc.detailViewController = self;
            vc.masterViewController = self.masterViewController;
            vc.remoteZone = self.remoteZone;
            vc.remoteTuner = self.remoteTuner;
        }
        
    }
}


#pragma mark - Alter View Appearance

- (void)resetView
{
    self.navigationItem.title = @"";
}

- (void)refreshViewConfiguration
{
    if (self.remoteZone) {
    
        self.zoneNameTextField.text = self.remoteZone.nameLong;
    
        BOOL volumeFound = NO;
        BOOL reloadVolumePicker = NO;
        
        if (self.volumeStrings) {
            [self.volumeStrings removeAllObjects];
            reloadVolumePicker = YES;
        } else {
            self.volumeStrings = [[NSMutableArray alloc] init];
        }
        
        for (Command *vc in self.remoteZone.volumeCommands) {
            [self.volumeStrings addObject:vc.parameter];
            if ([vc.parameter isEqualToString:self.remoteZone.volumeStatus.value]) {
                volumeFound = YES;
            }
        }
        
        if (!volumeFound) {
            [self rebuildVolumeCommands];
            reloadVolumePicker = YES;
        }
        
        if (reloadVolumePicker) {
            [self.volumePicker reloadComponent:0];
        }
        
        self.sourceList = self.remoteZone.sourceList;
        [self.sourcePicker reloadComponent:0];
        
        [self updateAutoOnButtons];
        
    } else {
        [self.volumeStrings addObject:@"-"];
    }
    
}

-(void)reloadData
{
    [self reloadTunerData];
    
    if (self.remoteZone) {

        [self.powerSwitch setOn:self.remoteZone.powerStatus.state];
        [self.muteSwitch setOn:self.remoteZone.muteStatus.state];
        [self updateAutoOnButtons];
        
        BOOL volumeFound = NO;
        for (NSInteger newRowIndex = 0; newRowIndex < [self.volumeStrings count]; newRowIndex++) {
            if ([self.remoteZone.volumeStatus.value isEqualToString:self.volumeStrings[newRowIndex]]) {
                [self.volumePicker selectRow:newRowIndex
                                 inComponent:0
                                    animated:YES];
                volumeFound = YES;
                break;  // break when we find the set volume
            }
        }
        if (!volumeFound) {
            [self rebuildVolumeCommands];
            [self.volumePicker reloadComponent:0];
            for (NSInteger newRowIndex = 0; newRowIndex < [self.volumeStrings count]; newRowIndex++) {
                if ([self.remoteZone.volumeStatus.value isEqualToString:self.volumeStrings[newRowIndex]]) {
                    [self.volumePicker selectRow:newRowIndex
                                     inComponent:0
                                        animated:YES];
                    break;  // break when we find the set volume
                }
            }
        }
        
        for (NSInteger newRowIndex = 0; newRowIndex < [self.remoteZone.sourceList count]; newRowIndex++) {
            Source *s = self.remoteZone.sourceList[newRowIndex];
            if ([self.remoteZone.sourceStatus.value isEqual:s.value]) {
                [self.sourcePicker selectRow:newRowIndex
                                  inComponent:0
                                     animated:YES];
                break;  // there only is one source, break when we find it
            }
        }
        
        if ((self.remoteZone.isDynamicZone) &&
            (self.isChangingFromRecordToZone) &&
            (self.remoteZone.modeStatus) &&
            ([self.remoteZone.modeStatus.value isEqualToString:@"Zone"]))
        {
            // The zone is changing dynamically from "record" to "zone"; turn the zone on and reset the flag
            Command *command = self.remoteZone.powerOnCommand;
            [command sendCommandToServer:self.remoteServer withPrefix:self.remoteZone.prefixValue];
            self.isChangingFromRecordToZone = NO;
        }
        
    } else {
        
        self.zoneNameTextField.text = @"";
        [self.powerSwitch setOn:0];
        [self.muteSwitch setOn:0];

        [self.volumePicker selectRow:0
                         inComponent:0
                            animated:NO];
        
        [self.sourcePicker selectRow:0
                         inComponent:0
                            animated:NO];
        
        [self.linkPicker selectRow:0
                       inComponent:0
                          animated:NO];
        
    }
    
}

-(void)reloadTunerData
{
    if (self.remoteTuner) {
        self.frequencyTextField.text = self.remoteTuner.frequencyText;
        self.presetTextField.text = self.remoteTuner.presetText;
    } else {
        self.frequencyTextField.text = @"";
        self.presetTextField.text = @"";
    }
}

- (void)rebuildVolumeCommands
{
    // The current volume is outside of the current range of the volume picker.
    // Use the ServerConfigHelper object to rebuild the volume strings, and then
    // rebuild the volume picker
    
    ServerConfigHelper *sch = [[ServerConfigHelper alloc] init];
    int fromValue = 0;
    int toValue = 0;
    
    if (([self.volumeStrings count] >0) &&
        [self.remoteZone.volumeStatus.value integerValue] < [self.volumeStrings[0] integerValue])
    {
        fromValue = [self.remoteZone.volumeStatus.value intValue];
        toValue = [self.volumeStrings[([self.volumeStrings count]-1)] intValue];
    } else {
        fromValue = [self.volumeStrings[0] intValue];
        toValue = [self.remoteZone.volumeStatus.value intValue];
    }
    
    [sch setVolumeRangeForZone:self.remoteZone
                     fromValue:(int)fromValue
                       toValue:(int)toValue];
    
    if (self.volumeStrings) {
        [self.volumeStrings removeAllObjects];
    } else {
        self.volumeStrings = [[NSMutableArray alloc] init];
    }
    
    for (Command *vc in self.remoteZone.volumeCommands)
    {
        [self.volumeStrings addObject:vc.parameter];
    }
}

- (void)updateAutoOnButtons
{
    if (self.remoteZone.powerStatus.state) {
        self.presetUpButton.backgroundColor = [UIColor colorWithRed:.6 green:.6 blue:.6 alpha:1];
        self.linkButton.backgroundColor = [UIColor colorWithRed:.6 green:.6 blue:.6 alpha:1];
    } else {
        if (self.userPreferences.enableAutoPowerOnTuner) {
            self.presetUpButton.backgroundColor = [UIColor colorWithRed:0 green:1 blue:0 alpha:1];
        }
        if (self.userPreferences.enableAutoPowerOnApps) {
            self.linkButton.backgroundColor = [UIColor colorWithRed:0 green:1 blue:0 alpha:1];
        }
    }
}


#pragma mark - Picker View Delegate, Picker View Data Source

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView
numberOfRowsInComponent:(NSInteger)component
{
    if (pickerView == self.sourcePicker) {
        return [self.sourceList count];
    }
    else if (pickerView == self.volumePicker) {
        return [self.volumeStrings count];
    }
    else if (pickerView == self.linkPicker) {
        return [self.hyperlinks count];
    }
    else {
        return 1;
    }
}

- (UIView *)pickerView:(UIPickerView *)pickerView
            viewForRow:(NSInteger)row
          forComponent:(NSInteger)component
           reusingView:(UIView *)view
{
    NSString *text = @"";
    
    if (pickerView == self.sourcePicker) {
        Source *s = self.sourceList[row];
        if (s) {
            text =  s.name;
        }
    }
    else if (pickerView == self.volumePicker) {
        text = self.volumeStrings[row];
    }
    else if (pickerView == self.linkPicker) {
        Hyperlink *h = self.hyperlinks[row];
        if (h) {
            text = h.name;
        }
    }
    
    UILabel *pickerLabel = (UILabel *)view;
    
    if (!pickerLabel)
    {
        pickerLabel = [[UILabel alloc] init];
        
        pickerLabel.font = [UIFont fontWithName:@"Helvetica Neue"
                                           size:18];
        
        pickerLabel.textAlignment=NSTextAlignmentCenter;
    }
    
    [pickerLabel setText:text];
    
    return pickerLabel;
}

- (void)pickerView:(UIPickerView *)pickerView
      didSelectRow:(NSInteger)row
       inComponent:(NSInteger)component
{
    if (pickerView == self.sourcePicker) {
        Source *source = self.sourceList[row];
        [source sendSourceCommandToServer:self.remoteServer withPrefix:self.remoteZone.prefixValue];
    }
    else if (pickerView == self.volumePicker) {
        Command *command = self.remoteZone.volumeCommands[row];
        [command sendCommandToServer:self.remoteServer withPrefix:self.remoteZone.prefixValue];
    }
    else if (pickerView == self.linkPicker) {

    }

    if (self.remoteZone.mustRequestStatus) {
        [self.remoteZone  sendRequestForStatus];
    }
}


#pragma mark - Actions

- (void)turnPowerOn
{
    // Set the power on command
    Command *command = nil;
    if (self.remoteZone.isDynamicZone) {
        
        // The zone is dynamically changed from "record" to "zone"...so first change it to zone
        command = self.remoteZone.modeZoneCommand;

        // Note that we do need to turn the zone on...
        // set a flag for that to happen above once it is detected that the zone mode changed to "Zone"
        self.isChangingFromRecordToZone = YES;

    } else {
        
        // It is normal zone, so just turn it on
        command = self.remoteZone.powerOnCommand;
        
    }
    
    // Send the power on command
    if (command) {
        [command sendCommandToServer:self.remoteServer withPrefix:self.remoteZone.prefixValue];
    }
    
    // Process the Tuner Override Zone
    if (self.remoteZone.tunerOverrideZoneUUID) {
        RemoteZone *tunerOverrideZone = [[RemoteZoneList sharedList] getZoneWithZoneUUID:self.remoteZone.tunerOverrideZoneUUID];
        [tunerOverrideZone.powerOnCommand sendCommandToServer:tunerOverrideZone.server withPrefix:tunerOverrideZone.prefixValue];
    }
    
    // Process any other zones this zone is dependent on
    if ([self.remoteZone.dependentZoneUUIDList count] > 0) {
        for (NSUUID *uuid in self.remoteZone.dependentZoneUUIDList) {
            RemoteZone *dependentZone = [[RemoteZoneList sharedList] getZoneWithZoneUUID:uuid];
            [dependentZone.powerOnCommand sendCommandToServer:dependentZone.server withPrefix:dependentZone.prefixValue];
        }
        
    }
    
    // Send the custom post-power-on string
    [self.remoteServer sendString:self.remoteZone.customPostPowerOnString];
    if (self.remoteZone.mustRequestStatus) {
        [self.remoteZone  sendRequestForStatus];
    }
}

- (void)turnPowerOff
{
    // Send the power on command
    if (self.remoteZone.isDynamicZone) {
        
        // The zone is dynamically configured from "record" to "zone"...so to turn it off just change back to "record"
        Command *command = self.remoteZone.modeRecordCommand;
        [command sendCommandToServer:self.remoteServer withPrefix:self.remoteZone.prefixValue];

        // Also set thse Zone to the copy-main source.  This is effectively what "record" is...and so setting the source to copy-main
        // will make more sence to the user in status displays
        for (NSInteger i = 0; i < [self.remoteZone.sourceList count]; i++) {
            Source *source = self.remoteZone.sourceList[i];
            if ([source.value isEqual:self.remoteServer.mainZoneSourceValue]) {
                [source sendSourceCommandToServer:self.remoteServer withPrefix:self.remoteZone.prefixValue];
                break;
            }
        }
    } else {
        
        // It is normal zone, so just turn it off
        Command *command = self.remoteZone.powerOffCommand;
        [command sendCommandToServer:self.remoteServer withPrefix:self.remoteZone.prefixValue];
        
    }
    
    // Process the Tuner Override Zone
    if (self.remoteZone.tunerOverrideZoneUUID) {
        [self requestTunerOverrideZonePowerOff];
    }
    
    // Process any other zones this zone is dependent on
    if ([self.remoteZone.dependentZoneUUIDList count] > 0) {
        [self requestDependentZonesPowerOff];
    }
    
    // Send the custom post-power-on string
    [self.remoteServer sendString:self.remoteZone.customPostPowerOffString];
    if (self.remoteZone.mustRequestStatus) {
        [self.remoteZone  sendRequestForStatus];
    }
}

- (void)requestTunerOverrideZonePowerOff
{
    if (![self otherZonesUsingOverrideTuner:self.remoteZone.tunerOverrideZoneUUID]) {
        RemoteZone *tunerOverrideZone = [[RemoteZoneList sharedList] getZoneWithZoneUUID:self.remoteZone.tunerOverrideZoneUUID];
        [tunerOverrideZone.powerOffCommand sendCommandToServer:tunerOverrideZone.server withPrefix:tunerOverrideZone.prefixValue];
    }
}

- (void)requestDependentZonesPowerOff
{
    for (NSUUID *uuid in self.remoteZone.dependentZoneUUIDList) {
        if (![self otherZonesUsingOverrideZone:uuid]) {
            RemoteZone *dependentZone = [[RemoteZoneList sharedList] getZoneWithZoneUUID:uuid];
            [dependentZone.powerOffCommand  sendCommandToServer:dependentZone.server withPrefix:dependentZone.prefixValue];
        }
        
    }
}

- (IBAction)powerSwitchChanged:(id)sender
{
    if (self.powerSwitch.isOn) {
        [self turnPowerOn];
    } else if (!self.powerSwitch.isOn) {
        [self turnPowerOff];
    }
}

- (IBAction)muteSwithChanged:(id)sender
{
    Command *command = nil;
    if (self.muteSwitch.isOn) {
        command = self.remoteZone.muteOnCommand;
    } else if (!self.muteSwitch.isOn) {
        command = self.remoteZone.muteOffCommand;
    }
    if (command) {
        [command sendCommandToServer:self.remoteServer withPrefix:self.remoteZone.prefixValue];
    }
    
    // If there is not a status value, then "mute" is probably a field the processor cannot report status on - so force a change
    // of the status to mach the new state.  And, some processors must be queried to report status - if that is the case here
    // then send that request.
    if ([self.remoteZone.muteStatus.value isEqualToString:@""]) {
        self.remoteZone.muteStatus.state = @(self.muteSwitch.isOn).intValue;
    } else if (self.remoteZone.mustRequestStatus) {
        [self.remoteZone sendRequestForStatus];
    }
}

- (IBAction)tunerPresetDown:(id)sender
{
    RemoteServer *server = self.remoteTuner.server;
    Command *command = self.remoteTuner.presetDownCommand;
    [command sendCommandToServer:server withPrefix:self.remoteTuner.prefixValue];
  
    if (self.remoteTuner.mustRequestStatus) {
        [self.remoteTuner  sendRequestForStatus];
    }
}

- (IBAction)tunerPresetUp:(id)sender
{
    if (self.remoteZone.powerStatus.state) {
        
        RemoteServer *server = self.remoteTuner.server;
        Command *command = self.remoteTuner.presetUpCommand;
        [command sendCommandToServer:server withPrefix:self.remoteTuner.prefixValue];

    } else if (self.userPreferences.enableAutoPowerOnTuner) {
    
        [self turnPowerOn];
        
        for (NSInteger i = 0; i < [self.remoteZone.sourceList count]; i++) {
            Source *source = self.remoteZone.sourceList[i];
            if ([source.value isEqual:self.remoteServer.tunerSourceValue]) {
                [source sendSourceCommandToServer:self.remoteServer withPrefix:self.remoteZone.prefixValue];
                break;
            }
        }
        
    }
    
    if (self.remoteTuner.mustRequestStatus) {
        [self.remoteTuner  sendRequestForStatus];
    }
}

- (IBAction)linkGo:(id)sender
{
    if ((!self.remoteZone.powerStatus.state) &&
        (self.userPreferences.enableAutoPowerOnApps)) {
        
        [self turnPowerOn];

        for (NSInteger i = 0; i < [self.remoteZone.sourceList count]; i++) {
            Source *source = self.remoteZone.sourceList[i];
            if ([source.value isEqual:self.remoteServer.autoOnSourceValue]) {
                [source sendSourceCommandToServer:self.remoteServer withPrefix:self.remoteZone.prefixValue];
                break;
            }
        }
    }
    
    if ([self.hyperlinks count]>0) {
        NSInteger selectedRow = [self.linkPicker selectedRowInComponent:0];
        Hyperlink *h = self.hyperlinks[selectedRow];
        NSURL *myURL = [NSURL URLWithString:h.address];
        UIApplication *application = [UIApplication sharedApplication];
        [application openURL:myURL options:@{} completionHandler:^(BOOL success) {
            if (success) {
                 NSLog(@"Opened url");
            }
        }];
    }
}


#pragma mark - Helpers

- (BOOL)otherZonesUsingOverrideTuner:(NSUUID *)uuid
{
    NSArray *zones = [[RemoteZoneList sharedList] zones];
    for (RemoteZone *z in zones) {
        if ([z.tunerOverrideZoneUUID.UUIDString isEqualToString:self.remoteZone.tunerOverrideZoneUUID.UUIDString]) {
            if (![z.zoneUUID.UUIDString isEqualToString:self.remoteZone.zoneUUID.UUIDString]){
                if (z.powerStatus.state) {
                    return YES;
                }
            }
        }
    }
    return NO;
}

- (BOOL)otherZonesUsingOverrideZone:(NSUUID *)uuid
{
    NSArray *zones = [[RemoteZoneList sharedList] zones];
    for (RemoteZone *z in zones) {
        if (![z.zoneUUID.UUIDString isEqualToString:self.remoteZone.zoneUUID.UUIDString]) {
            if ([z.dependentZoneUUIDList count] > 0) {
                for (NSUUID *zuuid in z.dependentZoneUUIDList) {
                    if ([zuuid.UUIDString isEqualToString:uuid.UUIDString]) {
                        if (z.powerStatus.state) {
                            return YES;
                        }
                    }
                }
            }
        }
    }
    return NO;
}

@end
