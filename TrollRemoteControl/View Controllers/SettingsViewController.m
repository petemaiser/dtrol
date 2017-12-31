//
//  SettingsViewController.m
//  GameCalc, TrollRemoteControl
//
//  Created by Pete Maiser on 12/19/15.
//  Copyright © 2015 Pete Maiser. All rights reserved.
//

#import "SettingsViewController.h"
#import "LinkCell.h"
#import "MasterViewController.h"
#import "SettingsList.h"
#import "Hyperlink.h"
#import "UserPreferences.h"
#import "Log.h"
#import "LogItem.h"

@interface SettingsViewController () <UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) NSDateFormatter *dateFormatter;
@property (weak, nonatomic) UITextField *activeField;

@property (weak, nonatomic) IBOutlet UISwitch *showZoneSetupSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *tunerAutoOnSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *airplayAutoOnSwitch;

@property (weak, nonatomic) IBOutlet UIButton *hyperlinksEditButton;
@property (weak, nonatomic) IBOutlet UITableView *hyperlinksTableView;

@end

@implementation SettingsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Configure helpers
    if (self.dateFormatter == nil) {
        self.dateFormatter = [[NSDateFormatter alloc] init];
        [self.dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        [self.dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
    }

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
    
    // Update the display to align with the current settings
    [self refreshSettingsFromStore];
    
    // Clear the selected row on the MVC
    [self.masterViewController.tableView deselectRowAtIndexPath:[self.masterViewController.tableView indexPathForSelectedRow] animated:NO];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)refreshSettingsFromStore
{
    SettingsList *settings = [SettingsList sharedSettingsList];
    // Rebuild settings
    if (settings) {
        [self.showZoneSetupSwitch setOn:settings.userPreferences.showZoneSetupButtons];
        [self.tunerAutoOnSwitch setOn:settings.userPreferences.enableAutoPowerOnTuner];
        [self.airplayAutoOnSwitch setOn:settings.userPreferences.enableAutoPowerOnAirplay];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // Save any settings that have not already been saved
    SettingsList *settings = [SettingsList sharedSettingsList];
    if (settings) {
        settings.userPreferences.enableAutoPowerOnTuner = self.tunerAutoOnSwitch.isOn;
        settings.userPreferences.enableAutoPowerOnAirplay = self.airplayAutoOnSwitch.isOn;
    }
}


#pragma mark - Actions

- (IBAction)editHyperlinks:(id)sender
{
    if (self.hyperlinksTableView.isEditing) {
        [self.hyperlinksEditButton setTitle:@"Edit" forState:UIControlStateNormal];
        [self.hyperlinksTableView setEditing:NO];
    } else {
        [self.hyperlinksEditButton setTitle:@"Done" forState:UIControlStateNormal];
        [self.hyperlinksTableView setEditing:YES];
    }
    
    [self resignFirstResponder];
}

- (IBAction)addHyperlink:(id)sender
{
    Hyperlink *link = [[Hyperlink alloc] initWithName:@"" address:@""];
    [[SettingsList sharedSettingsList] addHyperlink:link];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:([[[SettingsList sharedSettingsList] hyperlinks] count]-1) inSection:0];
    [self.hyperlinksTableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    
    [self resignFirstResponder];
}

- (IBAction)showZoneSetupSwichChanged:(id)sender
{
    SettingsList *settings = [SettingsList sharedSettingsList];
    settings.userPreferences.showZoneSetupButtons = self.showZoneSetupSwitch.isOn;
    [self.masterViewController refreshZoneSetupButtons];
}


#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[[SettingsList sharedSettingsList] hyperlinks] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    LinkCell *cell = [tableView dequeueReusableCellWithIdentifier:@"LinkCell" forIndexPath:indexPath];
    
    NSArray *links = [[SettingsList sharedSettingsList] hyperlinks];
    Hyperlink *link = links[indexPath.row];
    
    NSInteger nameCode = (indexPath.row * 10) + 1;
    NSInteger addressCode = (indexPath.row * 10) + 2;
    
    cell.hyperlinkNameTextField.text = link.name;
    cell.hyperlinkNameTextField.tag = nameCode;
    cell.hyperlinkAddressTextField.text = link.address;
    cell.hyperlinkAddressTextField.tag = addressCode;
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView *)tableView
    commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
     forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        NSArray *links = [[SettingsList sharedSettingsList] hyperlinks];
        Hyperlink *link = links[indexPath.row];
        
        [[SettingsList sharedSettingsList] deleteHyperlink:link];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        
        Hyperlink *link = [[Hyperlink alloc] initWithName:@"new" address:@"new address"];
     
        [[SettingsList sharedSettingsList] addHyperlink:link];
        
    }
}

- (void)tableView:(UITableView *)tableView
    moveRowAtIndexPath:(NSIndexPath *)fromIndexPath
           toIndexPath:(NSIndexPath *)toIndexPath
{
    [[SettingsList sharedSettingsList] moveLinkAtIndex:fromIndexPath.row
                                                 toIndex:toIndexPath.row];
    
    [tableView reloadData];
}


#pragma mark - Text Fields

- (void)touchesBegan:(NSSet *)touches
           withEvent:(UIEvent *)event
{
    // Dismiss Keyboard when the user touches the background
    [self.hyperlinksTableView endEditing:YES];
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
    self.hyperlinksTableView.contentInset = contentInsets;
    self.hyperlinksTableView.scrollIndicatorInsets = contentInsets;
    
    // If active text field is hidden by keyboard, scroll it so it's visible
    // Your app might not need or want this behavior.
    CGRect aRect = self.view.frame;
    aRect.size.height -= kbSize.height;
    if (!CGRectContainsPoint(aRect, self.activeField.frame.origin) ) {
        [self.hyperlinksTableView scrollRectToVisible:self.activeField.frame animated:YES];
    }
}

- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    self.hyperlinksTableView.contentInset = contentInsets;
    self.hyperlinksTableView.scrollIndicatorInsets = contentInsets;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [textField resignFirstResponder];
    self.activeField = nil;
    
    if (textField.tag % 10 == 1) {
        [[SettingsList sharedSettingsList] modifyHyperlinkAtIndex:textField.tag/10 name:textField.text address:nil];
    } else if (textField.tag % 10 == 2) {
        [[SettingsList sharedSettingsList] modifyHyperlinkAtIndex:textField.tag/10 name:nil address:textField.text];
    }
    
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    
    return YES;
}

@end
