//
//  ZoneSettingsTableViewController.m
//  TrollRemoteControl
//
//  Created by Pete Maiser on 2/16/17.
//  Copyright © 2017 Pete Maiser. All rights reserved.
//

#import "ZoneSettingsTableViewController.h"
#import "DetailViewController.h"
#import "MasterViewController.h"
#import "SourceSettingsViewController.h"
#import "TunerSettingsTableViewController.h"
#import "RemoteServer.h"
#import "RemoteZone.h"
#import "RemoteZoneList.h"
#import "RemoteTuner.h"
#import "Status.h"
#import "Command.h"
#import "ServerConfigHelper.h"

@interface ZoneSettingsTableViewController () <UITextFieldDelegate, UIPickerViewDelegate, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITextField *zoneLabel;
@property (weak, nonatomic) IBOutlet UITextField *zoneNameLongTextField;
@property (weak, nonatomic) IBOutlet UIPickerView *volumeMinPicker;
@property (weak, nonatomic) IBOutlet UIPickerView *volumeMaxPicker;

@property (weak, nonatomic) IBOutlet UITextField *ppOffCommandStringTextField;
@property (weak, nonatomic) IBOutlet UITextField *ppOnCommandStringTextField;


@property (weak, nonatomic) IBOutlet UITableViewCell *recordModeCell;
@property (weak, nonatomic) IBOutlet UILabel *recordModeForOffLabel;
@property (weak, nonatomic) IBOutlet UISwitch *recordModeForOffSwitch;

@property (weak, nonatomic) IBOutlet UITableViewCell *tunerSettingsCell;
@property (weak, nonatomic) IBOutlet UIButton *tunerSettingsButton;

@property (nonatomic, copy) NSString *minVolumeStringOriginal;
@property (nonatomic, copy) NSString *maxVolumeStringOriginal;
@property (nonatomic, copy) NSString *minVolumeStringSelected;
@property (nonatomic, copy) NSString *maxVolumeStringSelected;

@end

@implementation ZoneSettingsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Set delegates for the UITextFields
    self.zoneNameLongTextField.delegate = self;
    self.ppOnCommandStringTextField.delegate = self;
    self.ppOffCommandStringTextField.delegate = self;
    
    // Perform other setup
    self.minVolumeStringSelected = nil;
    self.maxVolumeStringSelected = nil;
    
    if (self.masterViewController.splitViewController.collapsed == NO) {
        self.masterViewController.zoneEditMode = YES;
    }
    
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self configureView];
}

- (void)configureView
{
    // Setup view title and data depending on how it is being used
    self.navigationItem.title = @"Zone Settings";
    
    // Configure view
    self.zoneLabel.text = self.remoteZone.nameShort;
    self.zoneNameLongTextField.text = self.remoteZone.nameLong;
    
    if (self.masterViewController.splitViewController.collapsed == NO) {
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                    target:self
                                                                                    action:@selector(closeZoneSettings:)];
        self.navigationItem.rightBarButtonItem = doneButton;
    }
    
    [self resetPickerView:self.volumeMinPicker animated:NO];
    [self resetPickerView:self.volumeMaxPicker animated:NO];
    
    if (self.remoteZone.volumeControlFixed.state) {
        self.volumeMinPicker.userInteractionEnabled = NO;
        self.volumeMaxPicker.userInteractionEnabled = NO;
    } else {
        self.volumeMinPicker.userInteractionEnabled = YES;
        self.volumeMaxPicker.userInteractionEnabled = YES;
    }

    self.ppOnCommandStringTextField.text = self.remoteZone.customPostPowerOnString;
    self.ppOffCommandStringTextField.text = self.remoteZone.customPostPowerOffString;
    
    if (self.remoteZone.isDynamicZoneCapable) {
        self.recordModeForOffLabel.hidden = NO;
        self.recordModeForOffSwitch.hidden = NO;
        self.recordModeCell.hidden = NO;
        [self.recordModeForOffSwitch setOn:self.remoteZone.isDynamicZone];
    } else {
        self.recordModeForOffLabel.hidden = YES;
        self.recordModeForOffSwitch.hidden = YES;
        self.recordModeCell.hidden = YES;
    }
    
    // Some components, e.g. Anthem pre-MRX components, do not support RS-232 access to tuner presets.
    // So we provide a custom Tuner Settings view to setup local presets (local to this app).
    // Hide it when we don't need it.
    if (self.remoteTuner.tunerPresetType == TunerPresetTypeRemote) {
        self.tunerSettingsButton.hidden = YES;
        self.tunerSettingsCell.hidden = YES;
    } else
        self.tunerSettingsButton.hidden = NO;
        self.tunerSettingsCell.hidden = NO;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // If the volume Min or Max settings changed, they need to be updated on the zone
    // which requires rebuilding the volume command array
    if (self.minVolumeStringSelected || self.maxVolumeStringSelected)
    {
        NSString *minVolumeStringNew = nil;
        NSString *maxVolumeStringNew = nil;
        
        if (self.minVolumeStringSelected) {
            minVolumeStringNew = self.minVolumeStringSelected;
        } else {
            minVolumeStringNew = self.minVolumeStringOriginal;
        }
        if (self.maxVolumeStringSelected) {
            maxVolumeStringNew = self.maxVolumeStringSelected;
        } else {
            maxVolumeStringNew = self.maxVolumeStringOriginal;
        }

        // Use the ServerConfigHelper object to rebuild the volume strings.
        // Do a final check for errors first - the min should not exceed the max,
        // and the current volume should not be outside the new range.
        // If error ignore the input.
        
        if ( ([minVolumeStringNew intValue] > [maxVolumeStringNew intValue]) ||
             ([minVolumeStringNew intValue] > [self.remoteZone.volumeStatus.value intValue]) ||
             ([maxVolumeStringNew intValue] < [self.remoteZone.volumeStatus.value intValue]) )
        {
            [self resetPickerView:self.volumeMinPicker animated:YES];
            [self resetPickerView:self.volumeMaxPicker animated:YES];
        }
        else
        {
            ServerConfigHelper *sch = [[ServerConfigHelper alloc] init];
            [sch setVolumeRangeForZone:self.remoteZone
                             fromValue:[minVolumeStringNew intValue]
                               toValue:[maxVolumeStringNew intValue] ];
            [self.detailViewController refreshViewConfiguration];
        }
    }
    
    if (self.remoteZone.isDynamicZoneCapable)
    {
        self.remoteZone.isDynamicZone = self.recordModeForOffSwitch.isOn;
    }
    
    // Protection of removing duplicates in case any were adding in the tuner settings.
    [self.remoteTuner removeStationDuplicates];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return 6;
    } else {
        return 2;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell* cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    
    if (cell.hidden) {
        return 0;
    }
    
    return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}


#pragma mark - Navigation

- (void)closeZoneSettings:(id)sender
{
    self.masterViewController.zoneEditMode = NO;
    [self performSegueWithIdentifier:@"closeZoneSettings" sender:sender];
}

- (IBAction)showSourceSettings:(id)sender
{
    [self performSegueWithIdentifier:@"showSourceSettings" sender:sender];
}
- (IBAction)showTunerSettings:(id)sender
{
    [self performSegueWithIdentifier:@"showTunerSettings" sender:sender];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue
                 sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showSourceSettings"]) {
        
        SourceSettingsViewController *ssvc = (SourceSettingsViewController *)[[segue destinationViewController] topViewController];
        
        if (ssvc) {
            ssvc.detailViewController = self.detailViewController;
            ssvc.masterViewController = self.masterViewController;
            ssvc.remoteZone = self.remoteZone;
        }
        
    } else if ([[segue identifier] isEqualToString:@"closeZoneSettings"]) {
        
        NSIndexPath *indexPath = [self.masterViewController.tableView indexPathForSelectedRow];
        
        NSArray *zones = [[RemoteZoneList sharedList] zones];
        RemoteZone *zone = zones[indexPath.row];
        
        DetailViewController *dvc = (DetailViewController *)[[segue destinationViewController] topViewController];
        
        if (dvc) {
            [dvc setRemoteZone:zone];
            dvc.masterViewController = self.masterViewController;
            dvc.existingItem = YES;
        }
        
    } else if ([[segue identifier] isEqualToString:@"showTunerSettings"]) {
        
        TunerSettingsTableViewController *tsvc = (TunerSettingsTableViewController *)[[segue destinationViewController] topViewController];
        
        if (tsvc) {
            tsvc.remoteTuner = self.remoteTuner;
        }

    }
}


#pragma mark - Text Fields

- (void)touchesBegan:(NSSet *)touches
           withEvent:(UIEvent *)event
{
    // Dismiss Keyboard when the user touches the background
    [self.zoneNameLongTextField resignFirstResponder];
    [self.ppOnCommandStringTextField resignFirstResponder];
    [self.ppOffCommandStringTextField resignFirstResponder];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    
    [textField resignFirstResponder];
    
    // Record the change
    if (textField == self.zoneNameLongTextField) {
        self.remoteZone.nameLong = self.zoneNameLongTextField.text;
        [self.detailViewController refreshViewConfiguration];
        [self.masterViewController reloadTable];
    } else if (textField == self.ppOnCommandStringTextField) {
        self.remoteZone.customPostPowerOnString = self.ppOnCommandStringTextField.text;
    } else if (textField == self.ppOffCommandStringTextField) {
        self.remoteZone.customPostPowerOffString = self.ppOffCommandStringTextField.text;
    }
    
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    
    return YES;
}


#pragma mark - Picker View Delegate, Picker View Data Source

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView
numberOfRowsInComponent:(NSInteger)component
{
    if (self.remoteZone.volumeControlFixed.state) {
        return 1;
    }
    else {
        return volumeMinMaxRange;
    }
}

- (UIView *)pickerView:(UIPickerView *)pickerView
            viewForRow:(NSInteger)row
          forComponent:(NSInteger)component
           reusingView:(UIView *)view
{
    NSString *text = @"";
    
    if (row < 0) {
        text = @"";
    }
    else if (pickerView == self.volumeMinPicker) {
        if (self.remoteZone.volumeControlFixed.state) {
            text = self.remoteZone.volumeStatus.value;
        } else {
            text = [NSString stringWithFormat:@"%d",(int)row + volumeMin];
        }
    }
    else if (pickerView == self.volumeMaxPicker) {
        if (self.remoteZone.volumeControlFixed.state) {
            text = self.remoteZone.volumeStatus.value;
        } else {
            text = [NSString stringWithFormat:@"%d",(int)row + 1 + volumeMax - volumeMinMaxRange];
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
    
    // Capture the new values, but wait until the view disappears before rebuilding the volume parameters for the zone.
    // And do a check for errors - the current volume should not be outside the new range.  Alert and reset if so.
    
    BOOL error = NO;
    
    if (pickerView == self.volumeMinPicker)
    {
        NSString *volumeSelected = [NSString stringWithFormat:@"%d", volumeMin + (int)row];
        
        if ([volumeSelected intValue] > [self.remoteZone.volumeStatus.value intValue])
        {
            [self resetPickerView:self.volumeMinPicker animated:YES];
            error = YES;
        } else {
            self.minVolumeStringSelected = volumeSelected;
        }
    }
    else if (pickerView == self.volumeMaxPicker)
    {
        NSString *volumeSelected = [NSString stringWithFormat:@"%d", volumeMax - volumeMinMaxRange + (int)row + 1];
        
        if ([volumeSelected intValue] < [self.remoteZone.volumeStatus.value intValue])
        {
            [self resetPickerView:self.volumeMaxPicker animated:YES];
            error = YES;
        } else {
            self.maxVolumeStringSelected = volumeSelected;
        }
    }

    if (error) {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@""
                                                                       message:@"Current volume must be within new Mix and Max.  Values have been reset."
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* closeAction = [UIAlertAction actionWithTitle:@"Close"
                                                              style:UIAlertActionStyleDefault
                                                            handler:nil];
        if (alert && closeAction) {
            [alert addAction:closeAction];
            [self presentViewController:alert animated:YES completion:nil];
        }
    }
    
}

- (void)resetPickerView:(UIPickerView *)pickerView
               animated:(BOOL)animated
{
    if (pickerView == self.volumeMinPicker) {
        Command *minVolumeCommand = self.remoteZone.volumeCommands[0];
        self.minVolumeStringOriginal = minVolumeCommand.parameter;
        int minVolumeIndex =  [self.minVolumeStringOriginal intValue] - volumeMin;
        [self.volumeMinPicker selectRow:minVolumeIndex
                            inComponent:0
                               animated:animated];
    }
    else if (pickerView == self.volumeMaxPicker) {
        NSInteger volumeCommandCount = [self.remoteZone.volumeCommands count];
        if (volumeCommandCount > 1) {
            Command *maxVolumeCommand = self.remoteZone.volumeCommands[volumeCommandCount-1];
            self.maxVolumeStringOriginal =  maxVolumeCommand.parameter;
        } else {
            self.maxVolumeStringOriginal = [self.minVolumeStringOriginal copy];
        }
        int maxVolumeIndex = [self.maxVolumeStringOriginal intValue] - (volumeMax - volumeMinMaxRange + 1);
        if (maxVolumeIndex < 0) {
            maxVolumeIndex = 0;
        }
        [self.volumeMaxPicker selectRow:maxVolumeIndex
                            inComponent:0
                               animated:animated];
    }
}

@end
