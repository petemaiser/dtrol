//
//  ServerFinder.m
//  DTrol
//
//  Created by Pete Maiser on 11/11/17.
//  Copyright © 2017 Pete Maiser. All rights reserved.
//
//  This program comes with ABSOLUTELY NO WARRANTY.
//  You are welcome to redistribute this software under certain conditions; see the included LICENSE file for details.
//

#import "ServerFinder.h"
#import "RemoteServer.h"
#import "ServerSetupController.h"
#import "NSString+ResponseString.h"

@interface ServerFinder()
@property  void (^callbackBlockForReceivedStrings)(NSString *);
@end

@implementation ServerFinder

#pragma mark - Initializer

- (instancetype)initWithServerSetupController:(ServerSetupController *)ssc
{
    self = [super init];
    
    if (self) {
        self.serverSetupController = ssc;
    }
    
    return self;
}


#pragma mark - Server Search

- (void)startServerSearch
{
    // This method should be called to start the server search - it should generally
    // be called by a notification that the Server Streams are connected.
    
    // This method needs to be extended by SubClasses for Brand-Model Specific Overrides
    
    self.serverSetupController.serverSetupStatus = ServerSetupStatusConnected;
    
    // Create a block to send to the RemoteServer for when it gets data back from the server
    __weak ServerFinder *weakSelf = self;
    self.callbackBlockForReceivedStrings = ^(NSString *responseString) {
        [weakSelf handleResponseString:responseString];
    };
    [self.serverSetupController.server addBlockForIncomingStrings:self.callbackBlockForReceivedStrings];

    self.serverSetupController.serverSetupStatus = ServerSetupStatusModelSearch;

}

- (void)abortServerSearch
{
    // Clear the callback block
    if (self.callbackBlockForReceivedStrings) {
        [self.serverSetupController.server removeBlockForIncomingStrings:self.callbackBlockForReceivedStrings];
    }
}

- (void)finishServerSearch
{
    // Clear the callback block
    if (self.callbackBlockForReceivedStrings) {
        [self.serverSetupController.server removeBlockForIncomingStrings:self.callbackBlockForReceivedStrings];
    }
    
    // Send out a notification that the Server has been found / the search is complete
    NSNotification *eventNotification = [NSNotification notificationWithName:ServerFoundNotificationString object:self.serverSetupController.server];
    if (eventNotification) {
        [[NSNotificationQueue defaultQueue] enqueueNotification:eventNotification
                                                   postingStyle:NSPostASAP
                                                   coalesceMask:NSNotificationCoalescingOnName
                                                       forModes:nil];
    }
}

#pragma mark - Server Interaction

- (void)handleResponseString:(NSString *)string
{
    // Subclasses need to override this method to process the Brand-Model Specific return string from the RemoteServer
}

@end
