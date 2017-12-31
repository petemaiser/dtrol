//
//  LogViewController.m
//  GameCalc, TrollRemoteControl
//
//  Created by Pete Maiser on 3/27/16.
//  Copyright © 2016 Pete Maiser. All rights reserved.
//

#import "LogViewController.h"
#import "MasterViewController.h"
#import "RemoteServer.h"
#import "Log.h"
#import "LogItem.h"

@interface LogViewController ()

@property (weak, nonatomic) IBOutlet UITextView *logTextView;
@property (nonatomic) NSInteger logItemsLoaded;

@end

@implementation LogViewController


- (void)viewDidLoad
{
    [super viewDidLoad];

    // Do initial Load of logitems
    self.logTextView.clearsOnInsertion = YES;
    [self loadLogItems];
    
    // Setup a reload when there is new data
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(loadMoreLogItems)
                                                 name:StreamNewDataNotificationString
                                               object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Clear the selected row on the MVC
    [self.masterViewController.tableView deselectRowAtIndexPath:[self.masterViewController.tableView indexPathForSelectedRow] animated:NO];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self scrollViewToBottom];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loadLogItems
{
    Log *sharedLog = [Log sharedLog];
    
    if (sharedLog) {
        
        self.logItemsLoaded = 0;
        NSArray *logItems = [sharedLog logItems];

        for (LogItem *logItem in logItems) {
            [self.logTextView insertText:logItem.text];
            [self.logTextView insertText:@"\n"];
            self.logItemsLoaded++;
        }
    }
}

- (void)scrollViewToBottom
{
    NSRange range = NSMakeRange(self.logTextView.text.length, 0);
    [self.logTextView scrollRangeToVisible:range];
}

- (void)loadMoreLogItems
{
    Log *sharedLog = [Log sharedLog];
    
    if (sharedLog) {
        
        NSInteger totalLogItems = [sharedLog.logItems count];
    
        for (NSInteger i = self.logItemsLoaded; i < totalLogItems; i++) {
  
            LogItem *logItem = sharedLog.logItems[i];
            [self.logTextView insertText:logItem.text];
            [self.logTextView insertText:@"\n"];
            self.logItemsLoaded++;
            
        }
    }

    [self scrollViewToBottom];
}

@end
