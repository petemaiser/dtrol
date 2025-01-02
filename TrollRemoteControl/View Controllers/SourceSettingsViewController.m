//
//  SourceSettingsViewController.m
//  TrollRemoteControl
//
//  Created by Pete Maiser on 2/11/17.
//  Copyright © 2017 Pete Maiser. All rights reserved.
//

#import "SourceSettingsViewController.h"
#import "SourceSettingsCell.h"
#import "DetailViewController.h"
#import "MasterViewController.h"
#import "RemoteServer.h"
#import "RemoteZone.h"
#import "Source.h"

@interface SourceSettingsViewController () <UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) UITextField *activeField;

@property (weak, nonatomic) IBOutlet UILabel *warningLabel;
@property (weak, nonatomic) IBOutlet UITableView *sourcesTableView;
@property (weak, nonatomic) IBOutlet UIPickerView *airplayAutoOnSourcePicker;   // now usually called "Apps Auto-On" instead of "Airplay Auto-On"

@end

@implementation SourceSettingsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Configure view

    self.warningLabel.text = [NSString stringWithFormat: @"WARNING - changing Source Settings here will impact Sources for all zones on the %@ Server.", self.remoteZone.server.nameShort];
    
    [self resetPickerView:self.airplayAutoOnSourcePicker animated:NO];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.remoteZone.server.sourceListAll count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SourceSettingsCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SourceSettingsCell" forIndexPath:indexPath];
    
    Source *s = self.remoteZone.server.sourceListAll[indexPath.row];
    
    cell.sourceLabel.text = [NSString stringWithFormat:@"Source %@", s.value];
    cell.sourceNameTextField.text = s.name;
    cell.sourceNameTextField.tag = indexPath.row;
    [cell.sourceEnabledSwitch setOn:s.enabled.boolValue];
    cell.sourceEnabledSwitch.tag = indexPath.row;
    [cell.sourceLabel setEnabled:YES];
    [cell.sourceNameTextField setEnabled:YES];
    [cell.sourceEnabledSwitch setEnabled:YES];

    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return NO;
}


#pragma mark - Picker View Delegate, Picker View Data Source

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView
numberOfRowsInComponent:(NSInteger)component
{
    return [self.remoteZone.server.sourceListAll count];
}

- (UIView *)pickerView:(UIPickerView *)pickerView
            viewForRow:(NSInteger)row
          forComponent:(NSInteger)component
           reusingView:(UIView *)view
{
    NSString *text = @"";
    
    if (row < 0) {
        text = @"";
    } else {
        Source *s = self.remoteZone.server.sourceListAll[row];
        text = [NSString stringWithFormat:@"Source %d", [s.value intValue]];
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
    Source *s = self.remoteZone.server.sourceListAll[row];
    self.remoteZone.server.autoOnSourceValue = s.value;
}

- (void)resetPickerView:(UIPickerView *)pickerView
               animated:(BOOL)animated
{
    if (pickerView == self.airplayAutoOnSourcePicker) {
        for (NSInteger i = 0; i < [self.remoteZone.server.sourceListAll count]; i++) {
            Source *s = self.remoteZone.server.sourceListAll[i];
            if ([s.value isEqual:self.remoteZone.server.autoOnSourceValue]) {
                [self.airplayAutoOnSourcePicker selectRow:i
                                              inComponent:0
                                                 animated:animated];
                break;
            }
        }
    }
}


#pragma mark - Text Fields

- (void)touchesBegan:(NSSet *)touches
           withEvent:(UIEvent *)event
{
    // Dismiss Keyboard when the user touches the background
    [self.sourcesTableView endEditing:YES];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    self.activeField = textField;
}

- (void)keyboardWasShown:(NSNotification*)aNotification
{
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
    self.sourcesTableView.contentInset = contentInsets;
    self.sourcesTableView.scrollIndicatorInsets = contentInsets;
    
    // If active text field is hidden by keyboard, scroll it so it's visible
    // Your app might not need or want this behavior.
    CGRect aRect = self.view.frame;
    aRect.size.height -= kbSize.height;
    if (!CGRectContainsPoint(aRect, self.activeField.frame.origin) ) {
        [self.sourcesTableView scrollRectToVisible:self.activeField.frame animated:YES];
    }
}

- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    self.sourcesTableView.contentInset = contentInsets;
    self.sourcesTableView.scrollIndicatorInsets = contentInsets;
}


- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [textField resignFirstResponder];
    self.activeField = nil;
    
    if (textField.tag >= 0) {
        Source *s = self.remoteZone.server.sourceListAll[textField.tag];
        s.name = textField.text;
        [self.detailViewController refreshViewConfiguration];
        [self.masterViewController reloadTable];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    
    return YES;
}


#pragma mark - Other Actions
- (IBAction)sourceEnabledSwitchChanged:(id)sender
{
    UISwitch *sourceSwitch = (UISwitch *)sender;
    if (sourceSwitch.tag >= 0) {
        Source *s = self.remoteZone.server.sourceListAll[sourceSwitch.tag];
        if (sourceSwitch.isOn) {
            s.enabled = @"Yes";
        }
        else {
            s.enabled = @"No";
            
            // Check on if we just disabled the Apps Auto-On Source (fka Airplay Source), and if so pick another enabled source
            if ([s.value isEqual:self.remoteZone.server.autoOnSourceValue]) {
                for (NSInteger i = 0; i < [self.remoteZone.server.sourceListAll count]; i++) {
                    Source *candidate = self.remoteZone.server.sourceListAll[i];
                    if (candidate.enabled.boolValue) {
                        self.remoteZone.server.autoOnSourceValue = candidate.value;
                        [self resetPickerView:self.airplayAutoOnSourcePicker animated:YES];
                        break;
                    }
                }
            }
    
            // Check on if we just disabled the last enabled Source, and if so
            // re enable the first source so the app doesn't crash later
            bool allSourcesDisabled = true;
            for (NSInteger i = 0; i < [self.remoteZone.server.sourceListAll count]; i++) {
                Source *check = self.remoteZone.server.sourceListAll[i];
                if (check.enabled.boolValue) {
                    allSourcesDisabled = false;
                    break;
                }
            }
            if (allSourcesDisabled) {
                Source *first = self.remoteZone.server.sourceListAll[0];
                first.enabled = @"Yes";
                self.remoteZone.server.autoOnSourceValue = first.value;
                [self resetPickerView:self.airplayAutoOnSourcePicker animated:YES];
                [self.sourcesTableView reloadData];
            }
        }
        [self.masterViewController reloadTable];
    }
}

- (IBAction)done:(id)sender
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}

@end
