//
//  AddServerTableViewController.m
//  TrollRemoteControl
//
//  Created by Pete Maiser on 2/18/17.
//  Copyright © 2017 Pete Maiser. All rights reserved.
//

#import "AddServerTableViewController.h"

#import "MasterViewController.h"
#import "DetailViewController.h"
#import "RemoteServer.h"
#import "RemoteServerList.h"
#import "UserPreferences.h"
#import "SettingsList.h"
#import "Reachability.h"
#import "ServerSetupController.h"
#import "Log.h"
#import "LogItem.h"

@interface AddServerTableViewController () <UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) NSDateFormatter *dateFormatter;
@property (strong, nonatomic) ServerSetupController *serverSetupController;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *saveButton;
@property (weak, nonatomic) IBOutlet UITextField *IPAddressTextField;
@property (weak, nonatomic) IBOutlet UITextField *portTextField;
@property (weak, nonatomic) IBOutlet UITextField *identifierTextField;
@property (strong, nonatomic) IBOutlet UIButton *findServerButton;
@property (weak, nonatomic) IBOutlet UITextView *feedbackTextView;
@property (strong, nonatomic) IBOutlet UITableViewCell *addDemoCell;
@property (strong, nonatomic) IBOutlet UIButton *addDemoServerButton;

@end


@implementation AddServerTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.serverSetupController = nil;
    self.saveButton.enabled = NO;
    
    if ([[[RemoteServerList sharedList] servers] count] < 2) {
        [self.addDemoCell setHidden:NO];
        [self.addDemoServerButton setEnabled:YES];
    } else {
        [self.addDemoServerButton setEnabled:NO];
        [self.addDemoCell setHidden:YES];
    }
    
    // Configure helpers
    self.feedbackTextView.clearsOnInsertion = YES;
    [self.feedbackTextView insertText:@""];
    if (self.dateFormatter == nil) {
        self.dateFormatter = [[NSDateFormatter alloc] init];
        [self.dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        [self.dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
    }
    
    // Setup handling for a reachability change
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reachabilityChanged:)
                                                 name:kReachabilityChangedNotification
                                               object:nil];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    Reachability *reachability = [Reachability sharedReachability];
    if ([reachability currentReachabilityStatus] != ReachableViaWiFi) {

        [self displayFeedbackTextString:@"Please connect via WiFi..."];
        [self lockViewUserInteraction];
        
    }
    [self configureView];
}

- (void)configureView
{
    // Setup view title and data depending on how it is being used
    self.navigationItem.title = @"Add Server";
}

- (void)reachabilityChanged:(NSNotification *)note
{
    Reachability* reachability = [note object];
    NSParameterAssert([reachability isKindOfClass:[Reachability class]]);
    
    if ([reachability currentReachabilityStatus] != ReachableViaWiFi) {
        
        [self displayFeedbackTextString:@"Please connect via WiFi..."];
        [self lockViewUserInteraction];

    } else if( [reachability currentReachabilityStatus] == ReachableViaWiFi) {
        
        [self displayFeedbackTextString:@"WiFi connection detected."];
        [self unlockViewUserInteraction];
        
    }
}

- (void)lockViewUserInteraction
{
    [self.findServerButton setEnabled:NO];
    [self.addDemoServerButton setEnabled:NO];
    [self.IPAddressTextField setEnabled:NO];
    [self.portTextField setEnabled:NO];
    [self.identifierTextField setEnabled:NO];
}

- (void)unlockViewUserInteraction
{
    [self.findServerButton setEnabled:YES];
    [self.addDemoServerButton setEnabled:YES];
    [self.IPAddressTextField setEnabled:YES];
    [self.portTextField setEnabled:YES];
    [self.identifierTextField setEnabled:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // Clear the first responder
    [self.view endEditing:YES];
    
    if (self.serverSetupController)
    {
        // Log the creation of the new item
        Log *sharedLog = [Log sharedLog];
        if (sharedLog) {
            [sharedLog addDivider];
            LogItem *logTextLineFirst = [LogItem logItemWithText:[NSString stringWithFormat:@"%s:  Server (%@) \"%@\" created: %@"
                                                                  ,getprogname()
                                                                  ,self.serverSetupController.server.nameShort
                                                                  ,self.serverSetupController.server.nameLong
                                                                  ,[self.dateFormatter stringFromDate:self.serverSetupController.server.dateCreated] ]];
            [sharedLog addItem:logTextLineFirst];
            [sharedLog addDivider];
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 6;
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

- (IBAction)cancel:(id)sender
{
    // Remove any items that were created
    if (self.serverSetupController) {
        [self.serverSetupController abortServerSetup];
        self.serverSetupController = nil;
    }

    // ~Refresh Master view, if needed
    if (self.masterViewController.splitViewController.displayMode == UISplitViewControllerDisplayModeAllVisible ) {
        
        [self.masterViewController reloadTable];
        
    }
    
    [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}

- (IBAction)save:(id)sender
{
    // ~Refresh Master view, if needed
    if (self.masterViewController.splitViewController.displayMode == UISplitViewControllerDisplayModeAllVisible ) {
        
        // Show the log view (only when in split view)
        if (self.masterViewController.splitViewController.collapsed == NO) {
            [self.masterViewController showLog:(self)];
        }
    }
    [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}


#pragma mark - Add Server

- (IBAction)findServer:(id)sender
{
    [self setupServer:self.identifierTextField.text
                    IP:self.IPAddressTextField.text
                  port:[self.portTextField.text intValue]
                  isDemo:NO];
}

- (IBAction)addDemoServer:(id)sender
{
    [self setupServer:self.identifierTextField.text
                    IP:self.IPAddressTextField.text
                  port:[self.portTextField.text intValue]
                isDemo:YES];
}

- (void)setupServer:(NSString *)nameShort
                            IP:(NSString *)serverIP
                          port:(uint)serverPort
                        isDemo:(BOOL)isDemo
{
    
    // If connected, start the Server Setup process
    Reachability *reachability = [Reachability sharedReachability];
    
    if ([reachability currentReachabilityStatus] == ReachableViaWiFi)
    {
        // Lock user interaction and use the ServerSetupController to manage the setup process
        [self lockViewUserInteraction];
        ServerSetupController *ssc = [[ServerSetupController alloc] initWithServerIP:serverIP port:serverPort identifier:nameShort isDemo:isDemo];
        self.serverSetupController  = ssc;
        
        // Create a block to send to the ServerSetupController for user feedback
        __weak AddServerTableViewController *weakSelf = self;
        self.serverSetupController.feedbackBlock = ^(NSString *feedbackString) {
            [weakSelf displayFeedbackTextString:feedbackString];
        };
        
        // Setup notifications for when the Server Setup is complete
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(serverSetupDidComplete)
                                                     name:ServerSetupCompleteNotificationString
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(serverSetupDidFail)
                                                     name:ServerSetupFailNotificationString
                                                   object:nil];

        // Kickoff the process
        [self displayFeedbackTextString:@"Finding Server..."];
        [self.serverSetupController startServerSetup];
    }
    else
    {
        [self displayFeedbackTextString:@"Please connect via WiFi and try again."];
    }
    
}

- (void)serverSetupDidComplete
{
    self.saveButton.enabled = YES;
    
}

- (void)serverSetupDidFail
{
    [self unlockViewUserInteraction];
}


#pragma mark - Text Fields

- (void)touchesBegan:(NSSet *)touches
           withEvent:(UIEvent *)event
{
    // Dismiss Keyboard when the user touches the background
    [self.tableView resignFirstResponder];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    
    [textField resignFirstResponder];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}


#pragma mark - Helpers

- (void)scrollViewToBottom
{
    NSRange range = NSMakeRange(self.feedbackTextView.text.length, 0);
    [self.feedbackTextView scrollRangeToVisible:range];
}

- (void)displayFeedbackTextString:(NSString *)string
{
    [self.feedbackTextView insertText:string];
    [self.feedbackTextView insertText:@"\n"];
    [self scrollViewToBottom];
}

@end
