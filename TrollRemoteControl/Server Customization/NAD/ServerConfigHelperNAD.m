//
//  ServerConfigHelperNAD.m
//
//  Created by Pete Maiser on 2/26/17.
//  This program comes with ABSOLUTELY NO WARRANTY.
//  You are welcome to redistribute this software under certain conditions; see the included LICENSE file for details.
//

#import "ServerConfigHelperNAD.h"
#import "NSString+ResponseString.h"
#import "RemoteServer.h"
#import "SourceNAD.h"
#import "Command.h"
#import "Status.h"
#import "RemoteServerList.h"
#import "RemoteTunerList.h"
#import "RemoteZoneList.h"
#import "RemoteTunerNAD.h"
#import "RemoteZoneNAD.h"
#import "DemoServers.h"

@interface ServerConfigHelperNAD ()

@property (weak, nonatomic) RemoteServer *server;       // Add a local server reference just to save some space/typing

@property (nonatomic) RemoteTuner *tuner;
@property (nonatomic) RemoteZone *zone1;
@property (nonatomic) RemoteZone *zone2;
@property (nonatomic) RemoteZone *zone3;
@property (nonatomic) RemoteZone *zone4;

@property (nonatomic, copy) NSString *zone1Volume;
@property (nonatomic, copy) NSString *zone2Volume;
@property (nonatomic, copy) NSString *zone2VolumeControl;
@property (nonatomic, copy) NSString *zone3Volume;
@property (nonatomic, copy) NSString *zone3VolumeControl;
@property (nonatomic, copy) NSString *zone4Volume;
@property (nonatomic, copy) NSString *zone4VolumeControl;

@property (nonatomic) NSMutableArray *sourceList;       // Use this Source List to Interrogate the server on source details and to configure Server Components.
#define NumberOfSources 10

@end

@implementation ServerConfigHelperNAD

#pragma mark - Initializer

- (instancetype)initWithServerSetupController:(ServerSetupController *)ssc
{
    self = [super initWithServerSetupController:ssc];
    if (self) {

        self.server = ssc.server;
        
        self.sourceList = [[NSMutableArray alloc] init];
        for (int i=1; i<=NumberOfSources; i++) {
            Command *c = [[Command alloc] initWithVariable:@".Source"
                                        parameterPrefix:@"="
                                              parameter:[NSString stringWithFormat:@"%d",i]];
            SourceNAD *s = [[SourceNAD alloc] initWithName:nil
                                            variable:@"Source"
                                               value:[NSString stringWithFormat:@"%d",i]
                                       sourceCommand:c
                                             enabled:nil];
            s.prefix = [NSString stringWithFormat:@"Source%d",i];
            [self.sourceList addObject:s];
        }

        self.zone1Volume            = nil;
        self.zone2Volume            = nil;
        self.zone3Volume            = nil;
        self.zone4Volume            = nil;
        self.zone2VolumeControl     = nil;
        self.zone3VolumeControl     = nil;
        self.zone4VolumeControl     = nil;
    }
    return self;
}


#pragma mark - Brand-Model Specific Overrides

- (void)createRemoteComponents
{
    // Subclasses of ServerSettingsHelper need to implement this method to create all RemoteComponents (Tuners and Zones)
    
    RemoteTunerNAD *tuner   = [[RemoteTunerNAD alloc] initTunerWithPrefixValue:@"Tuner"];
    RemoteZoneNAD *zone1    = [[RemoteZoneNAD alloc] initZoneWithPrefixValue:@"Main"];
    RemoteZoneNAD *zone2    = [[RemoteZoneNAD alloc] initZoneWithPrefixValue:@"Zone2"];
    RemoteZoneNAD *zone3    = [[RemoteZoneNAD alloc] initZoneWithPrefixValue:@"Zone3"];
    RemoteZoneNAD *zone4    = [[RemoteZoneNAD alloc] initZoneWithPrefixValue:@"Zone4"];
    if (tuner) {
        [self configureTunerNAD:tuner];
        self.tuner = tuner;
    }
    if (zone1) {
        [self configureZoneNAD:zone1];
        self.zone1 = zone1;
    }
    if (zone2) {
        [self configureZoneNAD:zone2];
        self.zone2 = zone2;
    }
    if (zone3) {
        [self configureZoneNAD:zone3];
        zone3.isDynamicZoneCapable = YES;
        self.zone3 = zone3;
    }
    if (zone4) {
        [self configureZoneNAD:zone4];
        zone4.isDynamicZoneCapable = YES;
        self.zone4 = zone4;
    }
}

- (void)sendRequestForVolumeInfo
{
    [self.server sendString:@"Main.Volume?"];
    [self.server sendString:@"Zone2.Volume?"];
    [self.server sendString:@"Zone3.Volume?"];
    [self.server sendString:@"Zone4.Volume?"];
    [self.server sendString:@"Zone2.VolumeControl?"];
    [self.server sendString:@"Zone3.VolumeControl?"];
    [self.server sendString:@"Zone4.VolumeControl?"];
}

- (void)sendRequestForSourceInfo
{
    [self.server sendString:@"Source1.Name?"];
    [self.server sendString:@"Source2.Name?"];
    [self.server sendString:@"Source3.Name?"];
    [self.server sendString:@"Source4.Name?"];
    [self.server sendString:@"Source5.Name?"];
    [self.server sendString:@"Source6.Name?"];
    [self.server sendString:@"Source7.Name?"];
    [self.server sendString:@"Source8.Name?"];
    [self.server sendString:@"Source9.Name?"];
    [self.server sendString:@"Source10.Name?"];
}

//- (void)sendRequestForOtherCustomInfo
//{
//    // Subclasses need to override this method if there are additional requests needed
//}

- (void)handleResponseString:(NSString *)string
{
    // Subclasses of ServerSettingsHelper need to implement this method to create all RemoteComponents (Tuners and Zones)
    
    // Use custom categories from NSString+ResponseString
    NSString *prefix = string.nad_prefix;
    NSString *variable = string.nad_variable;
    NSString *value = string.nad_value;
    
    if (prefix && variable && value) {
        if (       [variable isEqualToString:@"Name"]) {
            [self processSourceNameValue:value withPrefix:prefix];
        } else if ([variable isEqualToString:@"Enabled"]) {
            [self processSourceEnabledValue:value withPrefix:prefix];
        } else if ([variable isEqualToString:@"Volume"]) {
            [self processVolumeValue:value withPrefix:prefix];
        } else if ([variable isEqualToString:@"VolumeControl"]) {
            [self processVolumeControlValue:value withPrefix:prefix];
        }
    }
    
    // Check if we have enough information to complete the server configuration
    [self checkServerInterrogationStatus];
}

- (BOOL)haveVolumeInfo
{
    // Subclasses need to override this method to determine if they have received all the Volume status they requested
    if (self.zone1Volume            &&
        self.zone2Volume            &&
        self.zone2VolumeControl     &&
        self.zone3Volume            &&
        self.zone3VolumeControl     &&
        self.zone4Volume            &&
        self.zone4VolumeControl     )
    {
        return YES;
    }
    return NO;
}

- (BOOL)haveSourceInfo
{
    // Subclasses need to override this method to determine if they have received all the Source status they requested
    for (Source *s in self.sourceList) {
        if (!s.enabled || !s.name) {
            return NO;
        }
    }
    return YES;
}

//- (BOOL)haveOtherCustomInfo
//{
//    // Subclasses need to override this method to determine if they have received all the custom information requests needed
//    return YES;
//}

- (void)configureRemoteComponents
{
    // Subclasses of ServerConfigHelper need to override this method to copy completed Server Component Configuration over to the RemoteServer
    
    // Process and load Source Information
    int sourcesFoundCount = 0;
    for (Source *s in self.sourceList) {
        if (s.name) {
            [self.server addSource:s];
            sourcesFoundCount++;
        }
    }
    
    [self.serverSetupController postString:[NSString stringWithFormat:@"...%d sources found",sourcesFoundCount]
                                        to:PostStringDestinationLog|PostStringDestinationFeedback];
    
    
    
    // Create "Source 11", which seems to always be the "Copy Main" Source on NAD
    // Add it to appropriate sources below
    Command *c = [[Command alloc] initWithVariable:@".Source"
                                parameterPrefix:@"="
                                      parameter:@"11"];
    Source *copyMainSource = [[Source alloc] initWithName:@"Copy Main"
                                                 variable:@"Source"
                                                    value:@"11"
                                            sourceCommand:c
                                                  enabled:@"Yes"];
    // Process and load our Components
    if (self.tuner) {
        self.tuner.nameShort = [NSString stringWithFormat:@"%@ Tuner", self.server.nameShort];
        self.tuner.nameLong = [NSString stringWithFormat:@"%@ Tuner", self.server.model];
        [self.tuner setServerAsUUID:self.server.serverUUID];
        [[RemoteTunerList sharedList] addTuner:self.tuner];
    }
    if (self.zone1) {
        self.zone1.nameShort = [NSString stringWithFormat:@"%@ %@", self.server.nameShort, self.zone1.prefixValue];
        if ([self.zone1.nameLong isEqualToString:@""])
            self.zone1.nameLong = [NSString stringWithFormat:@"%@ %@ %@", self.server.nameShort, self.server.model, self.zone1.prefixValue];
        [self.zone1 setServerAsUUID:self.server.serverUUID];
        [[RemoteZoneList sharedList] addZone:self.zone1];
    }
    if (self.zone2) {
        self.zone2.nameShort = [NSString stringWithFormat:@"%@ Z2", self.server.nameShort];
        if ([self.zone2.nameLong isEqualToString:@""])
            self.zone2.nameLong = [NSString stringWithFormat:@"%@ %@ %@", self.server.nameShort, self.server.model, self.zone2.prefixValue];
        [self.zone2 addZoneSource:copyMainSource];
        [self.zone2 setServerAsUUID:self.server.serverUUID];
        [[RemoteZoneList sharedList] addZone:self.zone2];
    }
    if (self.zone3) {
        self.zone3.nameShort = [NSString stringWithFormat:@"%@ Z3", self.server.nameShort];
        if ([self.zone3.nameLong isEqualToString:@""])
            self.zone3.nameLong = [NSString stringWithFormat:@"%@ %@ %@", self.server.nameShort, self.server.model, self.zone3.prefixValue];
        [self.zone3 addZoneSource:copyMainSource];
        [self.zone3 setServerAsUUID:self.server.serverUUID];
        [[RemoteZoneList sharedList] addZone:self.zone3];
    }
    if (self.zone4) {
        self.zone4.nameShort = [NSString stringWithFormat:@"%@ Z4", self.server.nameShort];
        if ([self.zone4.nameLong isEqualToString:@""])
            self.zone4.nameLong = [NSString stringWithFormat:@"%@ %@ %@", self.server.nameShort, self.server.model, self.zone4.prefixValue];
        [self.zone4 addZoneSource:copyMainSource];
        [self.zone4 setServerAsUUID:self.server.serverUUID];
        [[RemoteZoneList sharedList] addZone:self.zone4];
    }
}

//- (void)setTunerSource
//{
//    // Extend or Override this if more sophistication is needed to find the tuner vs scanning the simple name-scanning the super class does
//}

- (void)setMainZoneSource
{
    // Subclasses of ServerSettingsHelper need to implement this to complete settings on the min and max volume ranges
    self.server.mainZoneSourceValue = @"11";
}

- (void)setVolumeSettings
{
    // Subclasses of ServerSettingsHelper need to implement this to complete settings on the min and max volume ranges
    [self setVolumeRangeForZone:self.zone1 withVolumeControlStatus:@"Variable" withBaseVolume:self.zone1Volume];
    [self setVolumeRangeForZone:self.zone2 withVolumeControlStatus:self.zone2VolumeControl withBaseVolume:self.zone2Volume];
    [self setVolumeRangeForZone:self.zone3 withVolumeControlStatus:self.zone3VolumeControl withBaseVolume:self.zone3Volume];
    [self setVolumeRangeForZone:self.zone4 withVolumeControlStatus:self.zone4VolumeControl withBaseVolume:self.zone4Volume];
}

- (void)sendRequestForStatus
{
    // Subclasses of ServerSettingsHelper need to implement this to send a message to all RemoteComponents
    // to send a request for Status (all Tuners and Zones)
    [self.tuner sendRequestForStatus];
    [self.zone1 sendRequestForStatus];
    [self.zone2 sendRequestForStatus];
    [self.zone3 sendRequestForStatus];
    [self.zone4 sendRequestForStatus];
}


#pragma mark - Local Helpers

- (void)configureTunerNAD:(RemoteTunerNAD *)tuner
{
    tuner.bandStatus              = [[Status alloc] initWithVariable:@".Band"
                                                        commandValue:@"?"];
    
    tuner.AMFrequencyStatus       = [[Status alloc] initWithVariable:@".AM.Frequency"
                                                        commandValue:@"?"];
    tuner.AMFrequencyStatus.state = RemoteStatusStateOff;
    
    tuner.FMFrequencyStatus       = [[Status alloc] initWithVariable:@".FM.Frequency"
                                                        commandValue:@"?"];
    tuner.FMFrequencyStatus.state = RemoteStatusStateOff;
    
    tuner.presetStatus            = [[Status alloc] initWithVariable:@".Preset"
                                                        commandValue:@"?"];
    tuner.presetUpCommand         = [[Command alloc] initWithVariable:@".Preset"
                                                   parameterPrefix:@""
                                                         parameter:@"+"];
    tuner.presetDownCommand       = [[Command alloc] initWithVariable:@".Preset"
                                                   parameterPrefix:@""
                                                         parameter:@"-"];
    
    // Create a set of the Stati for fast enumeration in the RemoteZone Component
    tuner.statusSet = [[NSSet alloc] initWithObjects:tuner.bandStatus,
                                                     tuner.presetStatus,
                                                     tuner.AMFrequencyStatus,
                                                     tuner.FMFrequencyStatus,
                                                     nil];
}

- (void)configureZoneNAD:(RemoteZoneNAD *)zone
{
    zone.powerStatus       = [[Status alloc] initWithVariable:@".Power"
                                                 commandValue:@"?"];
    zone.powerStatus.state = RemoteStatusStateOff;
    zone.powerOnCommand    = [[Command alloc] initWithVariable:@".Power"
                                            parameterPrefix:@"="
                                                  parameter:@"On"];
    zone.powerOffCommand   = [[Command alloc] initWithVariable:@".Power"
                                            parameterPrefix:@"="
                                                  parameter:@"Off"];
    
    zone.modeStatus        = [[Status alloc] initWithVariable:@".Mode"
                                                 commandValue:@"?"];
    zone.modeZoneCommand   = [[Command alloc] initWithVariable:@".Mode"
                                            parameterPrefix:@"="
                                                  parameter:@"Zone"];
    zone.modeRecordCommand = [[Command alloc] initWithVariable:@".Mode"
                                            parameterPrefix:@"="
                                                  parameter:@"Record"];
    
    zone.volumeControlFixed = [[Status alloc] initWithVariable:@".VolumeControl"
                                                  commandValue:@"?"];
    zone.volumeControlFixed.state = RemoteStatusStateOff;
    zone.volumeStatus      = [[Status alloc] initWithVariable:@".Volume"
                                                 commandValue:@"?"];
    zone.volumeCommandTemplate = [[Command alloc] initWithVariable:@".Volume"
                                                parameterPrefix:@"="
                                                      parameter:@""]; // An array of Volume commands should be setup too
    
    zone.muteStatus        = [[Status alloc] initWithVariable:@".Mute"
                                                 commandValue:@"?"];
    zone.muteStatus.state  = RemoteStatusStateOff;
    zone.muteOnCommand     = [[Command alloc] initWithVariable:@".Mute"
                                            parameterPrefix:@"="
                                                  parameter:@"On"];
    zone.muteOffCommand    = [[Command alloc] initWithVariable:@".Mute"
                                            parameterPrefix:@"="
                                                  parameter:@"Off"];
    
    zone.sourceStatus      = [[Status alloc] initWithVariable:@".Source"
                                                 commandValue:@"?"];
    
    // Create a set of the Stati for fast enumeration in the RemoteZone Component
    zone.statusSet = [[NSSet alloc] initWithObjects:zone.powerStatus,
                                                    zone.volumeStatus,
                                                    zone.sourceStatus,
                                                    zone.muteStatus,
                                                    zone.modeStatus,
                                                    zone.volumeControlFixed,
                                                    nil];
}

- (void)processSourceNameValue:(NSString *)nameValue
                    withPrefix:(NSString *)prefix
{
    for (SourceNAD *s in self.sourceList) {
        if ([s.prefix isEqualToString:prefix]) {
            s.name = nameValue;
            [self.serverSetupController postString:[NSString stringWithFormat:@"%@ found as %@.", prefix, nameValue]
                          to:PostStringDestinationLog];
            NSString *sourceStatusCommandString = [NSString stringWithFormat:@"%@.Enabled?",prefix];
            [self.server sendString:sourceStatusCommandString];
            break;
        }
    }
}

- (void)processSourceEnabledValue:(NSString *)enabledValue
                       withPrefix:(NSString *)prefix
{
    NSString *nameValue = nil;
    BOOL found = NO;
    for (SourceNAD *s in self.sourceList) {
        if ([s.prefix isEqualToString:prefix]) {
            s.enabled = enabledValue;
            nameValue = s.name;
            found = YES;
            break;
        }
    }
    if (found && enabledValue.boolValue) {
        [self.serverSetupController postString:[NSString stringWithFormat:@"%@ (%@) is enabled.", prefix, nameValue]
                                   to:PostStringDestinationLog];
    }
}

- (void)processVolumeValue:(NSString *)volumeValue
                withPrefix:(NSString *)prefix
{
    if (       [prefix isEqualToString:@"Main"]) {
        self.zone1Volume = volumeValue;
    } else if ([prefix isEqualToString:@"Zone2"]) {
        self.zone2Volume = volumeValue;
    } else if ([prefix isEqualToString:@"Zone3"]) {
        self.zone3Volume = volumeValue;
    } else if ([prefix isEqualToString:@"Zone4"]) {
        self.zone4Volume = volumeValue;
    }
}

- (void)processVolumeControlValue:(NSString *)volumeControlValue
                       withPrefix:(NSString *)prefix
{
    if (       [prefix isEqualToString:@"Zone2"]) {
        self.zone2VolumeControl = volumeControlValue;
    } else if ([prefix isEqualToString:@"Zone3"]) {
        self.zone3VolumeControl = volumeControlValue;
    } else if ([prefix isEqualToString:@"Zone4"]) {
        self.zone4VolumeControl = volumeControlValue;
    }
}


#pragma mark - Demo Mode

- (void)processDemoMode:(NSInteger)demoMode
{
    
    // Subclasses of ServerSettingsHelper need to extend this method to enable demo and test of their Settings Help without the need for a server on-hand
    // Subclass implementation should call this method
    // Setup connection parameters in this class's header file.
    
    [super processDemoMode:demoMode];
    
    #define preLoadComponents 0
    #define customizeComponents 1
    
    if (self.serverSetupController.serverSetupStatus == ServerSetupStatusModelFound) {
        
        if (preLoadComponents)
        {
            // Bypass the requests and fill in the information manually
            self.mustRequestSourceInfo = NO;
            self.mustRequestVolumeInfo = NO;
            
            // Fill in info here...
            
            [self checkServerInterrogationStatus];
        }
        else
        {
            if (self.mustRequestVolumeInfo) {
                [self sendRequestForVolumeInfo];
            }
            if (self.mustRequestSourceInfo) {
                [self sendRequestForSourceInfo];
            }
//            if (self.mustRequestOtherCustomInfo) {
//                [self sendRequestForOtherCustomInfo];
//            }
        }
        
    }
    
    if ((customizeComponents) &&
        (self.serverSetupController.serverSetupStatus == ServerSetupStatusInnterogationSuccess))
    {
        
        // The components have been built via interogation, lets fill-in additional demo server details if we have them.
        // Start by finding the demoServer configuration dictionary
        NSDictionary *demoServer = nil;
        DemoServers *ds = [[DemoServers alloc] init];
        for (NSDictionary *d in ds.list) {
            
            NSString *demoIP = [d objectForKey:@"serverIP"];
            if ([demoIP isEqualToString:self.server.IP]) {
                demoServer = d;
                break;
            }
            
        }
        
        self.server.customIfString = [demoServer objectForKey:@"customIfString"];
        self.server.customThenString = [demoServer objectForKey:@"customThenString"];
        
        if (self.zone1) {
            self.zone1.nameLong = [demoServer objectForKey:@"zone1.nameLong"];
            self.zone1.isHidden = [[demoServer objectForKey:@"zone1.isHidden"] boolValue];
        }
        if (self.zone2) {
            self.zone2.nameLong = [demoServer objectForKey:@"zone2.nameLong"];
            self.zone2.isHidden = [[demoServer objectForKey:@"zone2.isHidden"] boolValue];
        }
        if (self.zone3) {
            self.zone3.nameLong = [demoServer objectForKey:@"zone3.nameLong"];
            self.zone3.isHidden = [[demoServer objectForKey:@"zone3.isHidden"] boolValue];
        }
        if (self.zone4) {
            self.zone4.nameLong = [demoServer objectForKey:@"zone4.nameLong"];
            self.zone4.isHidden = [[demoServer objectForKey:@"zone4.isHidden"] boolValue];
        }
        
        NSString *tunerOverrideIP = [demoServer objectForKey:@"tunerOverride.IP"];
        if (![tunerOverrideIP isEqualToString:@""]) {
            
            // Disable the local Tuner Source
            Source *s = self.sourceList[9]; s.enabled = @"N";
            
            // Fine the tuner zone
            NSString *tunerOverrideZoneNameLong = [demoServer objectForKey:@"tunerOverride.zone.nameLong"];
            RemoteZone *tunerZone =  [self getZoneWithServerIP:tunerOverrideIP andZoneNameLong:tunerOverrideZoneNameLong];
            
            // Set the tuner zone as a overide on all of this servers zones

            if (self.zone1) {
                self.zone1.tunerOverrideZoneUUID = tunerZone.zoneUUID;
            }
            if (self.zone2) {
                self.zone2.tunerOverrideZoneUUID = tunerZone.zoneUUID;
            }
            if (self.zone3) {
                self.zone3.tunerOverrideZoneUUID = tunerZone.zoneUUID;
            }
            if (self.zone4) {
                self.zone4.tunerOverrideZoneUUID = tunerZone.zoneUUID;
            }
            
        }
        
    }

}

@end
