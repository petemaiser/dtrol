//
//  ServerSetupController.m
//  DTrol
//
//  Created by Pete Maiser on 11/11/17.
//  Copyright © 2017 Pete Maiser. All rights reserved.
//

#import "ServerSetupController.h"
#import "RemoteServer.h"
#import "ServerFinderALL.h"
#import "ServerConfigHelper.h"
#import "RemoteServerList.h"
#import "RemoteTunerList.h"
#import "RemoteZoneList.h"
#import "SettingsList.h"
#import "UserPreferences.h"
#import "Log.h"
#import "LogItem.h"

@interface ServerSetupController()
@property  void (^callbackBlockForReceivedStrings)(NSString *);
@property (nonatomic) NSInteger demoMode;
@end

@implementation ServerSetupController

#pragma mark - Initializer

- (instancetype)initWithServerIP:(NSString *)serverIP
                            port:(uint)serverPort
                      identifier:(NSString *)nameShort
                          isDemo:(BOOL)isDemo
{
    self = [super init];
    
    if (self) {
        
        if (isDemo) {
            self.demoMode = 1;
            if ([nameShort isEqualToString:@""]) {
                nameShort = DemoServerIdentifier;
            }
            if ([serverIP isEqualToString:@""]) {
                serverIP = DemoServerIPAddress;
            }
            if (serverPort == 0) {
                serverPort = DemoServerPort;
            }
        } else {
            self.demoMode = 0;
        }
        
        RemoteServer *server = [RemoteServer createServerWithIP:serverIP port:serverPort lineTerminationString:@"\r"];
        
        [[RemoteServerList sharedList] addServer:server];
        server.nameShort = nameShort;

        self.server = server;
        self.serverSetupStatus = ServerSetupStatusNotConnected;
        
        // Setup a request to start the Search when streams are opened
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(startServerSearch)
                                                     name:StreamsReadyNotificationString
                                                   object:server];
        
        // Setup a request to start the Server config when the Server is found
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(startServerConfiguration)
                                                     name:ServerFoundNotificationString
                                                   object:server];
        
        // Setup a request to complete the Server configuration when appropriate
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(finishServerConfiguration)
                                                     name:ServerInterrogationCompleteNotificationString
                                                   object:server];
        
        // Setup a request to handle errors in stream-opening (probably due to a server not found)
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleStreamError)
                                                     name:StreamErrorNotificationString
                                                   object:server];
    }
    
    return self;
}

#pragma mark - Step O Connect to the IP Address (Server)

- (void)startServerSetup
{
    SettingsList *settings = [SettingsList sharedSettingsList];
    [NSTimer scheduledTimerWithTimeInterval:settings.userPreferences.timeout
                                     target:self
                                   selector:@selector(checkServerConfigurationStatus)
                                   userInfo:nil
                                    repeats:NO];
    
    [self.server openStreams];
}


#pragma mark - Step 1 Search for Server (Find Server)

- (void)startServerSearch
{
    // Startup the Server Finder
    ServerFinderALL *finder = [[ServerFinderALL alloc] initWithServerSetupController:self];
    finder.serverSetupController = self;
    self.serverFinder = finder;
    
    [self.serverFinder startServerSearch];
}


#pragma mark - Step 2 Configure Server

- (void)startServerConfiguration
{
    // The Server Finder should have initialized the appropriate ServerConfigHelper (different Models use different helpers)
    // Start the Configuration process
    self.serverConfgHelper.demoMode = self.demoMode;
    [self.serverConfgHelper startServerConfiguration];
}


#pragma mark - Step 3 Complete Server Configuration

- (void)finishServerConfiguration
{
    [self.serverConfgHelper finishServerConfiguration];
}


#pragma mark - Check Status

- (void)checkServerConfigurationStatus
{
    // Check the Status on the overall Server Configuration process, and inform and/or process accordingly.
    // This would primarily be used in anomaly cases, for the "happy path" the flow will push itself along
    
    switch(self.serverSetupStatus) {
            
        case ServerSetupStatusNotConnected:{
            
            // If we are checking status we must have timed-out, and we didn't even get connected to anything
            [self postString:@"ERROR:  Server not found, or is not responding.  Check the IP Address and Port." to:PostStringDestinationFeedback];
            [self postString:@"Try again, or touch Cancel to return to the Zones view without adding this Server." to:PostStringDestinationFeedback];
            [self postString:@"" to:PostStringDestinationFeedback];
            
            self.serverSetupStatus = ServerSetupStatusInnterogationTimeOut;
            [self abortServerSetup];
            
        } break;
            
        case ServerSetupStatusConnected:
        case ServerSetupStatusModelSearch:{
            
            // If we are checking status we must have timed-out, but we at least connected.
            
            [self postString:@"ERROR:  Server was found, but could not be identified.  Check the connection between the network and the processor or receiver, and check that your model is supported." to:PostStringDestinationFeedback];
            [self postString:@"Try again, or touch Cancel to return to the Zones view without adding this Server." to:PostStringDestinationFeedback];
            [self postString:@"" to:PostStringDestinationFeedback];
            
            // Abort
            self.serverSetupStatus = ServerSetupStatusInnterogationTimeOut;
            [self abortServerSetup];
            
        } break;
            
        case ServerSetupStatusModelFound:
        case ServerSetupStatusInnterogation:{
            
            // Interrogation started...if we are checking status we must have timed-out so presumably the Interrogation cannot complete successfully.
            // But we would still have enough to Configure the Server, so force the configuration with what we have.
            self.serverSetupStatus = ServerSetupStatusInnterogationTimeOut;
            [self finishServerConfiguration];
            
        } break;
            
        case ServerSetupStatusInnterogationTimeOut:{
            // This is already handled above
            
        } break;
            
        case ServerSetupStatusInnterogationSuccess:{
            // Nothing to do, the normal flow should push this along
            
        } break;
            
        case ServerSetupStatusComplete:{
            // Nothing to do, the normal flow should push this along
            
        } break;
            
    }
    
}


#pragma mark - Handle  Configuration Anomolies

- (void)handleStreamError
{
    // Give the user a warning
    [self postString:@"WARNING:  Communication Error - check your WiFi connection, and check the connection between the network and the processor or receiver."
                  to:PostStringDestinationFeedback];
    
}

- (void)abortServerSetup
{
    // Clear the callback block
    if (self.callbackBlockForReceivedStrings) {
        [self.server removeBlockForIncomingStrings:self.callbackBlockForReceivedStrings];
    }
    
    // Clear out the notifications -- we will set them up again if the user tries again
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:StreamsReadyNotificationString
                                                  object:self.server];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:ServerFoundNotificationString
                                                  object:self.server];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:ServerInterrogationCompleteNotificationString
                                                  object:self.server];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:StreamErrorNotificationString
                                                  object:self.server];
    
    // Clean-up and delete the helpers -- we will set them up again if the user tries again
    if (self.serverFinder) {
        [self.serverFinder abortServerSearch];
        self.serverFinder = nil;
    }
    if (self.serverConfgHelper) {
        [self.serverConfgHelper abortServerConfiguration];
        self.serverConfgHelper = nil;
    }
    
    // Send a message to close the streams and delete the RemoteServer
    if (self.server) {
        [self.server closeStreams];
        [[RemoteTunerList sharedList] deteleTunersWithServer:self.server];
        [[RemoteZoneList sharedList] deteleZonesWithServer:self.server];
        [[RemoteServerList sharedList] deleteServer:self.server];
        self.server = nil;
    }
    
    // Send out a notification about the failure
    NSNotification *eventNotification = [NSNotification notificationWithName:ServerSetupFailNotificationString object:self];
    if (eventNotification) {
        [[NSNotificationQueue defaultQueue] enqueueNotification:eventNotification
                                                   postingStyle:NSPostASAP
                                                   coalesceMask:NSNotificationCoalescingOnName|NSNotificationCoalescingOnSender                                                       forModes:nil];
    }
}


#pragma mark - Helpers

- (void)postString:(NSString *)string
                to:(NSUInteger)destination
{
    if (destination & PostStringDestinationLog) {
        Log *sharedLog = [Log sharedLog];
        if (sharedLog) {
            LogItem *logTextLine1 = [LogItem logItemWithText:[NSString stringWithFormat:@"PROCESSED (%@):  %@",self.server.nameShort, string]];
            [sharedLog addItem:logTextLine1];
        }
    }
    if (destination & PostStringDestinationFeedback) {
        self.feedbackBlock(string);
    }
}

@end
