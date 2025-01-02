//
//  ServerConfigHelper.m
//
//  Created by Pete Maiser on 2/26/17.
//  Copyright © 2017 Pete Maiser. All rights reserved.
//  This program comes with ABSOLUTELY NO WARRANTY.
//  You are welcome to redistribute this software under certain conditions; see the included LICENSE file for details.
//

#import "ServerConfigHelper.h"
#import "ServerSetupController.h"
#import "RemoteServer.h"
#import "RemoteServerList.h"
#import "RemoteZone.h"
#import "RemoteZoneList.h"
#import "Command.h"
#import "Source.h"
#import "Log.h"
#import "LogItem.h"

@interface ServerConfigHelper()
@property  void (^callbackBlockForReceivedStrings)(NSString *);
@end

@implementation ServerConfigHelper

#pragma mark - Initializer

- (instancetype)initWithServerSetupController:(ServerSetupController *)ssc
{
    self = [super init];
    
    if (self) {
        self.serverSetupController = ssc;
        self.demoMode = 0;
        self.mustRequestSourceInfo = YES;
        self.mustRequestVolumeInfo = YES;
        self.mustRequestOtherCustomInfo = NO;
    }
    
    // Subclasses generally should generally implement this method to continue (or override) initiatization steps
    return self;
}


#pragma mark - Start the Server Configuration

- (void)startServerConfiguration
{
    // This method should be called to start the settings configuration process after the Server is found
    
    // Generally this method should not have to be implemented by subclasses - see the called methods
    // below and override those instead
    
    // Create a block to send to the RemoteServer for when it gets data back from the server
    __weak ServerConfigHelper *weakSelf = self;
    self.callbackBlockForReceivedStrings = ^(NSString *responseString) {
        [weakSelf handleResponseString:responseString];
    };
    [self.serverSetupController.server addBlockForIncomingStrings:self.callbackBlockForReceivedStrings];
    
    // Frame-out the RemoteComponents (Tuners and Zones)
    [self createRemoteComponents];

    // Kick-off the process of interrogating the server to identify settings
    [self startServerInterrogation];

}


#pragma mark - Server Interrogation Flow

- (void)startServerInterrogation
{
    // Generally this method should not have to be implemented by subclasses

    if (self.demoMode) {
    
        // Process the demo mode (demo mode also useful for testing when developing brand-specific ServerSettingsHelpers)
        [self processDemoMode:self.demoMode];

    } else {
        
        // Request information, if needed for this type
        if (self.mustRequestVolumeInfo) {
            [self sendRequestForVolumeInfo];
        }
        if (self.mustRequestSourceInfo) {
            [self sendRequestForSourceInfo];
        }
        if (self.mustRequestOtherCustomInfo) {
            [self sendRequestForOtherCustomInfo];
        }
        
        self.serverSetupController.serverSetupStatus = ServerSetupStatusInnterogation;
        
    }
}

- (void)checkServerInterrogationStatus
{
    // Check the Status on the overall Server Configuration process, and inform and/or process accordingly.
    // This would likely be called frequently as part of the Interrogation process to see if we are "done",
    // and move the process along if we are done.
    // Generally this method should not have to be implemented by subclasses
    
    if ([self haveVolumeInfo] &&
        [self haveSourceInfo] &&
        [self haveOtherCustomInfo] &&
        (self.serverSetupController.serverSetupStatus != ServerSetupStatusInnterogationTimeOut)) // if it timed-out then the timeout will complete the interrogation
    {
        self.serverSetupController.serverSetupStatus = ServerSetupStatusInnterogationSuccess;
        
        // Send out a notification that the Interrogation has completed
        NSNotification *eventNotification = [NSNotification notificationWithName:ServerInterrogationCompleteNotificationString
                                                                          object:self.serverSetupController.server];
        if (eventNotification) {
            [[NSNotificationQueue defaultQueue] enqueueNotification:eventNotification
                                                       postingStyle:NSPostASAP
                                                       coalesceMask:NSNotificationCoalescingOnName|NSNotificationCoalescingOnSender                                                       forModes:nil];
        }
        
    }
}


#pragma mark - End the Server Configuration

- (void)abortServerConfiguration
{
    // Clear the callback block
    if (self.callbackBlockForReceivedStrings) {
        [self.serverSetupController.server removeBlockForIncomingStrings:self.callbackBlockForReceivedStrings];
    }
}

- (void)finishServerConfiguration
{
    // Generally this method should NOT have to be implemented by subclasses - see the called methods below and override those
    
    if (![self haveVolumeInfo] && ![self haveSourceInfo]) {
        [self.serverSetupController postString:@"WARNING:  Server found, but setup may be incomplete.  There may have been a communication problem.  You can continue with this server, if the setup does not seem complete then delete all zones for this server and try again." to:PostStringDestinationFeedback];
    } else if (![self haveSourceInfo]) {
        [self.serverSetupController postString:@"WARNING:  Server found, but fewer sources found than expected.  There may have been a communication problem.  You can continue with this server, but if some sources are missing delete all zones for this server and try again." to:PostStringDestinationFeedback];
    } else if (![self haveVolumeInfo]) {
        [self.serverSetupController postString:@"WARNING:  Server found, but fewer zones found than expected.  There may have been a communication problem.  You can continue with this server, but if some sources are missing delete all zones for this server and try again." to:PostStringDestinationFeedback];
    }
    
    // Clear the callback block
    if (self.callbackBlockForReceivedStrings) {
        [self.serverSetupController.server removeBlockForIncomingStrings:self.callbackBlockForReceivedStrings];
    }
    
    // Load the Settings to the RemoteServer
    [self configureRemoteComponents];
    
    // Process the demo mode for additional customizations
    if (self.demoMode) {
        [self processDemoMode:self.demoMode];
    }
    
    // Set the Apps Auto-On Source
    [self setAutoOnSource];
    
    // Set the Tuner Source
    [self setTunerSource];
    
    // Set the Main Zone Source
    [self setMainZoneSource];
    
    // Set the volume Settings
    [self setVolumeSettings];
    
    // All RemoteComponents should send a request for Status (all Tuners and Zones)
    [self sendRequestForStatus];
    
    // Declare completion
    self.serverSetupController.serverSetupStatus = ServerSetupStatusComplete;
    [self.serverSetupController postString:@"" to:PostStringDestinationFeedback];
    [self.serverSetupController postString:@"Touch Save to add Server.  Unneeded Zones can be deleted via the Zones view;  use the Settings views for additional customization."
                                        to:PostStringDestinationFeedback];
    [self.serverSetupController postString:@"Or touch Cancel to return to the Zones view without adding this Server."
                                        to:PostStringDestinationFeedback];
    
    NSNotification *eventNotification = [NSNotification notificationWithName:ServerSetupCompleteNotificationString object:self];
    if (eventNotification) {
        [[NSNotificationQueue defaultQueue] enqueueNotification:eventNotification
                                                   postingStyle:NSPostASAP
                                                   coalesceMask:NSNotificationCoalescingOnName|NSNotificationCoalescingOnSender
                                                       forModes:nil];
    }
    
}


#pragma mark - Brand-Model Specific Overrides

- (void)createRemoteComponents
{
    // Subclasses need to override this method to create and configure all RemoteComponents (Tuners and Zones) per Brand-Model Specific requirements
}

- (void)sendRequestForVolumeInfo
{
    // Subclasses need to override this method to send requests for the current volume in each zone
}

- (void)sendRequestForSourceInfo
{
    // Subclasses need to override this method to send requests about source status
    // (if supported by this Brand-Model)
}

- (void)sendRequestForOtherCustomInfo
{
    // Subclasses need to override this method if there are additional custom information requests needed
}

- (void)handleResponseString:(NSString *)string
{
    // Subclasses need to override this method to process the Brand-Model Specific Overrides return string from the RemoteServer
}

- (BOOL)haveVolumeInfo
{
    // Subclasses need to override this method to determine if they have received all the Volume status they requested
    return YES;
}

- (BOOL)haveSourceInfo
{
    // Subclasses need to override this method to determine if they have received all the Source status they requested
    return YES;
}

- (BOOL)haveOtherCustomInfo
{
    // Subclasses need to override this method to determine if they have received all the custom information requests needed
    return YES;
}

- (void)configureRemoteComponents
{
    // Subclasses of ServerConfigHelper need to override this method to copy completed RemoteComponent configuration over to the RemoteServer
}

- (void)setMainZoneSource
{
    // Subclasses need to override this method to complete settings on the min and max volume ranges
}

- (void)setVolumeSettings
{
    // Subclasses need to override this method to complete settings on the min and max volume ranges
}

- (void)sendRequestForStatus
{
    // Subclasses need to override this method to send a message to all RemoteComponents to send a request
    // for Status (all Tuners and Zones), to extend that is supported by the Brand-Model
}


#pragma mark - Helpers to set source markers

- (void)setAutoOnSource
{
    // See if we can identify one of the sources as "Airplay" for Apps Auto-On
    if (self.serverSetupController.server) {
        NSArray *nameList = [[NSArray alloc] initWithObjects:@"Airplay", @"Air", @"AIRPLAY", @"air", nil];
        Source *source = [self sourceWithNameInArray:nameList];
        if (source) {
            [self.serverSetupController postString:[NSString stringWithFormat:@"...Apps Auto-On Source set to Source %@", source.value]
                                                to:PostStringDestinationFeedback];
            self.serverSetupController.server.autoOnSourceValue = source.value;
        } else {
            if ([self.serverSetupController.server.sourceListAll count] > 0) {
                Source *firstSource = self.serverSetupController.server.sourceList[0];
                [self.serverSetupController postString:[NSString stringWithFormat:@"...Airplay source not found; Apps Auto-On Source will be set to Source %@", firstSource.value]
                                                    to:PostStringDestinationFeedback];
                self.serverSetupController.server.autoOnSourceValue = firstSource.value;
            } else {
                self.serverSetupController.server.autoOnSourceValue = @"";
            }
        }
    }
}

- (void)setTunerSource
{
    // See if we can identify one of the sources as the Tuner
    if (self.serverSetupController.server) {
        NSArray *nameList = [[NSArray alloc] initWithObjects:@"Tuner", @"TUNER", @"tuner", @"Rack Tuner", nil];
        Source *source = [self sourceWithNameInArray:nameList];
        if (source) {
            [self.serverSetupController postString:[NSString stringWithFormat:@"...Tuner source set to Source %@", source.value]
                                                to:PostStringDestinationFeedback];
            self.serverSetupController.server.tunerSourceValue = source.value;
        } else {
            self.serverSetupController.server.tunerSourceValue = @"";
            [self.serverSetupController postString:@"WARNING:  Tuner source not identified.  Some functions of DTrol will not function without a Tuner.  If your processeor or receiver has a tuner, cancel and try again."
                                                to:PostStringDestinationLog|PostStringDestinationFeedback];
        }
    }
}

#pragma mark - General Helpers

- (void)setVolumeRangeForZone:(RemoteZone *)zone
      withVolumeControlStatus:(NSString *)volumeControlStatus
               withBaseVolume:(NSString *)baseVolume
{
    int fromValue = 0;
    int toValue = 0;
    
    if ([volumeControlStatus isEqualToString:@"Fixed"]) {
        fromValue = [baseVolume intValue];
        toValue = [baseVolume intValue];
    } else if ([baseVolume intValue] <= -60) {
        fromValue = -80;
        toValue = -40;
    } else if ([baseVolume intValue] <= -30) {
        fromValue = -45;
        toValue = -15;
    } else {
        fromValue = ([baseVolume intValue]-30);
        toValue = ([baseVolume intValue]+10);
    }
    
    [self setVolumeRangeForZone:zone fromValue:fromValue toValue:toValue];
}

- (void)setVolumeRangeForZone:(RemoteZone *)zone
                    fromValue:(int)fromValue
                        toValue:(int)toValue
{
    if (zone.volumeCommandTemplate == nil) {
        [NSException raise:@"Incomplete Setup"
                    format:@"setVolumeRangeFromValue:toValue called without setting Volume Command Template"];
    }
    else {
        if (zone.volumeCommands) {
            [zone.volumeCommands removeAllObjects];
        } else {
            zone.volumeCommands = [[NSMutableArray alloc] init];
        }
        if (zone.usesVolumeHalfSteps) {
            for (int i = fromValue; i <= toValue; i++) {
                Command *command = [zone.volumeCommandTemplate copy];
                command.parameter = [NSString stringWithFormat:@"%d.0", i];
                [zone.volumeCommands addObject:command];
                if (i < toValue) {
                    Command *commandHalf = [zone.volumeCommandTemplate copy];
                    commandHalf.parameter = [NSString stringWithFormat:@"%d.5", i+1];
                    [zone.volumeCommands addObject:commandHalf];
                }
            }
        } else {
            for (int i = fromValue; i <= toValue; i++) {
                Command *command = [zone.volumeCommandTemplate copy];
                command.parameter = [NSString stringWithFormat:@"%d", i];
                [zone.volumeCommands addObject:command];
            }
        }
    }
}

- (Source *)sourceWithNameInArray:(NSArray *)nameList
{
    // Check for an exact match in enabled sources
    if ([self.serverSetupController.server.sourceList count] > 0) {
        for (Source *source in self.serverSetupController.server.sourceList)
        {
            for (NSString *name in nameList)
            {
                if ([source.name isEqualToString:name]) {
                    return source;
                }
            }
        }
    }
    
    // Check for an exact match in all sources
    if ([self.serverSetupController.server.sourceListAll count] > 0) {
        for (Source *source in self.serverSetupController.server.sourceListAll)
        {
            for (NSString *name in nameList)
            {
                if ([source.name isEqualToString:name]) {
                    return source;
                }
            }
        }
    }
    
    // Check if any enabled sources contain the string
    if ([self.serverSetupController.server.sourceList count] > 0) {
        for (Source *source in self.serverSetupController.server.sourceList)
        {
            for (NSString *name in nameList)
            {
                if ([source.name containsString:name]) {
                    return source;
                }
            }
        }
    }
    
    // Check if any sources contain the string
    if ([self.serverSetupController.server.sourceListAll count] > 0) {
        for (Source *source in self.serverSetupController.server.sourceListAll)
        {
            for (NSString *name in nameList)
            {
                if ([source.name containsString:name]) {
                    return source;
                }
            }
        }
    }
    
    // Not found
    return nil;
}

- (RemoteZone *)getZoneWithServerIP:(NSString *)IP
                    andZoneNameLong:(NSString  *)znl
{
    // First find the server
    RemoteServer *server = nil;
    NSArray *servers = [[RemoteServerList sharedList] servers];
    for (RemoteServer *s in servers) {
        if ([s.IP isEqualToString:IP]) {
            server = s;
            break;
        }
    }
    
    // Then the zone
    RemoteZone *zone = nil;
    NSArray *zones = [[RemoteZoneList sharedList] zones];
    for (RemoteZone *z in zones) {
        if ([z.nameLong isEqualToString:znl]) {
            zone = z;
            break;
        }
    }
    
    return zone;
    
}


#pragma mark - Demo Mode

- (void)processDemoMode:(NSInteger)demoMode
{
    // Subclasses need to implement this to enable demo and test of their Settings Help without the need for a server on-hand
    // Subclass implementation should call this method
    
}


@end
