//
//  TunerSettingsTableViewController.m
//  DTrol
//
//  Created by Pete Maiser on 12/6/17.
//  Copyright © 2017 Pete Maiser. All rights reserved.
//

#import "TunerSettingsTableViewController.h"
#import "TunerSettingsCell.h"
#import "RemoteTuner.h"
#import "TunerStation.h"

@interface TunerSettingsTableViewController ()

@property (weak, nonatomic) UITextField *activeField;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *doneButton;

@end

@implementation TunerSettingsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];

     self.navigationItem.leftBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Table view

- (void)setEditing:(BOOL)editing
          animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    
    if (editing) {
        
        UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                    target:self
                                                                                    action:@selector(addStation)];
        self.navigationItem.rightBarButtonItem = addButton;
        
        
    } else {
        self.navigationItem.rightBarButtonItem = self.doneButton;
    }
    
}

- (void)addStation
{
    // Create a new Station object
    const char *className = object_getClassName(self.remoteTuner.stations[0]);
    Class tunerStationClass = NSClassFromString([NSString stringWithUTF8String:className]);
    TunerStation *newStation = [[tunerStationClass alloc] init];
    [self.remoteTuner.stations addObject:newStation];
    
    // Add it to the table
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:([self.remoteTuner.stations count]-1) inSection:0];
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.remoteTuner.stations count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    TunerSettingsCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TunerSettingsCell" forIndexPath:indexPath];
    
    // Configure the cell...
    TunerStation  *station = self.remoteTuner.stations[indexPath.row];
    cell.presetLabel.text = [NSString stringWithFormat:@"%ld", indexPath.row + (long)1];
    cell.presetStationText.text = station.frequencyText;
    cell.presetStationText.tag = indexPath.row;
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    if ([self.remoteTuner.stations count] == 1) {
        return NO;
    } else {
        return YES;
    }
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self.remoteTuner.stations removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        [tableView reloadData];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {

    }   
}

// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    if (fromIndexPath.row == toIndexPath.row){
        return;
    }
    
    TunerStation *station = self.remoteTuner.stations[fromIndexPath.row];
    [self.remoteTuner.stations removeObjectAtIndex:fromIndexPath.row];
    if (station) {
        [self.remoteTuner.stations insertObject:station atIndex:toIndexPath.row];
    }
    
    [self.tableView reloadData];
}


#pragma mark - Text Fields

- (void)touchesBegan:(NSSet *)touches
           withEvent:(UIEvent *)event
{
    // Dismiss Keyboard when the user touches the background
    [self.tableView endEditing:YES];
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
    self.tableView.contentInset = contentInsets;
    self.tableView.scrollIndicatorInsets = contentInsets;
    
    // If active text field is hidden by keyboard, scroll it so it's visible
    // Your app might not need or want this behavior.
    CGRect aRect = self.view.frame;
    aRect.size.height -= kbSize.height;
    if (!CGRectContainsPoint(aRect, self.activeField.frame.origin) ) {
        [self.tableView scrollRectToVisible:self.activeField.frame animated:YES];
    }
}

- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    self.tableView.contentInset = contentInsets;
    self.tableView.scrollIndicatorInsets = contentInsets;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [textField resignFirstResponder];
    self.activeField = nil;
    
    if (textField.tag >= 0) {
        TunerStation *ts = self.remoteTuner.stations[textField.tag];
        ts.frequencyText = textField.text;

    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    
    return YES;
}


#pragma mark - Other Actions

- (IBAction)done:(id)sender
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}

@end
