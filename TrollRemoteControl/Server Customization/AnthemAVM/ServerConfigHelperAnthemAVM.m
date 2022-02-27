//
//  ServerConfigHelperAnthemAVM.m
//
//  Created by Pete Maiser on 3/2/17.
//  This program comes with ABSOLUTELY NO WARRANTY.
//  You are welcome to redistribute this software under certain conditions; see the included LICENSE file for details.
//

#import "ServerConfigHelperAnthemAVM.h"
#import "RemoteServer.h"
#import "Source.h"
#import "Command.h"
#import "Status.h"
#import "RemoteServerList.h"
#import "RemoteTunerList.h"
#import "RemoteZoneList.h"
#import "RemoteTunerAnthemAVM.h"
#import "RemoteZoneAnthemAVM.h"
#import "TunerStationAnthemAVM.h"
#import "CommandAnthemAVMPresetUp.h"
#import "CommandAnthemAVMPresetDown.h"
#import "DemoServers.h"

@interface ServerConfigHelperAnthemAVM ()

@property (weak, nonatomic) RemoteServer *server;           // Add a local server reference just to save some space/typing

@property (nonatomic) RemoteTuner *tuner;
@property (nonatomic) RemoteZone *zone1;
@property (nonatomic) RemoteZone *zone2;
@property (nonatomic) RemoteZone *zone3;

@property (nonatomic, copy) NSString *zone1Volume;
@property (nonatomic, copy) NSString *zone2Volume;
@property (nonatomic, copy) NSString *zone3Volume;

@property (nonatomic) NSMutableArray *sourceList;           // Use this Source List to configure Server Components.
@property (nonatomic) NSMutableArray *frequencyTextList;    // Use the Preset List to configure the Local Preset Stations

@end

@implementation ServerConfigHelperAnthemAVM

#pragma mark - Initializer

- (instancetype)initWithServerSetupController:(ServerSetupController *)ssc
{
    self = [super initWithServerSetupController:ssc];
    if (self) {
        self.server = ssc.server;
        self.mustRequestSourceInfo      = NO;
        self.mustRequestOtherCustomInfo = YES;
        
        self.zone1Volume                = nil;
        self.zone2Volume                = nil;
        self.zone3Volume                = nil;
        self.sourceList                 = [[NSMutableArray alloc] init];
        
        self.frequencyTextList = [[NSMutableArray alloc] init];
        for (int i=1; i<=(banksFM*presetsFM+presetsAM); i++) {
            [self.frequencyTextList addObject:@""];
        }
    }
    return self;
}


#pragma mark - Brand-Model Specific Overrides

- (void)createRemoteComponents
{
    // Subclasses need to override this method to create and configure all RemoteComponents (Tuners and Zones) per Brand-Model Specific requirements
    
    RemoteTunerAnthemAVM *tuner   = [[RemoteTunerAnthemAVM alloc] initTunerWithPrefixValue:@"T"];
    RemoteZoneAnthemAVM *zone1    = [[RemoteZoneAnthemAVM alloc] initZoneWithPrefixValue:@"P1"];
    RemoteZoneAnthemAVM *zone2    = [[RemoteZoneAnthemAVM alloc] initZoneWithPrefixValue:@"P2"];
    RemoteZoneAnthemAVM *zone3    = [[RemoteZoneAnthemAVM alloc] initZoneWithPrefixValue:@"P3"];

    if (tuner) {
        [self configureTunerAnthemAVM:tuner];
        self.tuner = tuner;
    }
    if (zone1) {
        [self configureZoneAnthemAVM:zone1 withVolumeCommandVariable:@"VM"];
        self.zone1 = zone1;
    }
    if (zone2) {
        [self configureZoneAnthemAVM:zone2 withVolumeCommandVariable:@"V"];
        self.zone2 = zone2;
    }
    if (zone3) {
        [self configureZoneAnthemAVM:zone3 withVolumeCommandVariable:@"V"];
        self.zone3 = zone3;
    }
}

- (void)sendRequestForVolumeInfo
{
    // Subclasses need to override this method to send requests for the current volume in each zone
    [self.server sendString:@"P1VM?"];
    [self.server sendString:@"P2V?"];
    [self.server sendString:@"P3V?"];
}

// Nothing can be queried about Anthem pre-MRX AVM sources
//- (void)sendRequestForSourceInfo
//{
//    // Subclasses need to override this method to send requests for the information on sources
//    // (if supported by this Brand-Model)
//
//}

- (void)sendRequestForOtherCustomInfo
{
    // Subclasses need to override this method if there are additional requests needed
    
    // Request a set of Tuner Presets to pre-populate our Local Presets.  Start with the first FM bank.
    for (int y=1; y<=presetsFM; y++) {
        [self.server sendString:[NSString stringWithFormat:@"TFS%d%d?",1,y]];
    }
}

- (void)handleResponseString:(NSString *)string
{
    // Subclasses need to override this method to process the Brand-Model Specific Overrides return string from the RemoteServer
    
    if ([string hasPrefix:@"P1VM"])
    {
        self.zone1Volume = [string substringFromIndex:4];
    }
    else if ([string hasPrefix:@"P2V"])
    {
        self.zone2Volume = [string substringFromIndex:3];
    }
    else if ([string hasPrefix:@"P3V"])
    {
        self.zone3Volume = [string substringFromIndex:3];
    }
    else if (([string hasPrefix:@"TFS"]) &&
               (string.length > 6))
    {
        int x = [string characterAtIndex:3] - '0';
        int y = [string characterAtIndex:4] - '0';
        int presetIndex = (x*presetsFM)-presetsFM+y-1;
        NSString *frequencyNumberText = [[string substringFromIndex:6] stringByReplacingOccurrencesOfString:@" " withString:@""];
        if (presetIndex < [self.frequencyTextList count]) {
            self.frequencyTextList[presetIndex] = [NSString stringWithFormat:@"%@ FM", frequencyNumberText];
        }
        // When this preset is at the "end" of a bank, call the next bank
        if ( (presetIndex+1) % presetsFM == 0) {
            if ( presetIndex+1 < banksFM*presetsFM) {
                int nx = (presetIndex+1)/presetsFM + 1;
                for (int ny=1; ny<=presetsFM; ny++) {
                    [self.server sendString:[NSString stringWithFormat:@"TFS%d%d?",nx,ny]];
                }
            } else {
                // Call the AM bank
                for (int ny=1; ny<=presetsAM; ny++) {
                    [self.server sendString:[NSString stringWithFormat:@"TAS%d?",ny]];
                }
            }
        }
    }
    else if (([string hasPrefix:@"TAS"]) &&
               (string.length > 5))
    {
        int y = [string characterAtIndex:3] - '0';
        int presetIndex = (banksFM*presetsFM)+y-1;
        NSString *frequencyNumberText = [[string substringFromIndex:5] stringByReplacingOccurrencesOfString:@" " withString:@""];
        if (presetIndex < [self.frequencyTextList count]) {
            self.frequencyTextList[presetIndex] = [NSString stringWithFormat:@"%@ AM", frequencyNumberText];
        }
    }
    
    // Check if we have enough information to complete the server configuration
    [self checkServerInterrogationStatus];
}

- (BOOL)haveVolumeInfo
{
    // Subclasses need to override this method to determine if they have received all the Volume status they requested
    if (self.zone1Volume &&
        self.zone2Volume &&
        self.zone3Volume)
    {
        return YES;
    } else {
        return NO;
    }
    
}

// Nothing can be queried about Anthem sources
//- (BOOL)haveSourceInfo
//{
//    // Subclasses need to override this method to send requests about source status
//    // (if supported by this Brand-Model)
//
//    return YES;
//}

- (BOOL)haveOtherCustomInfo
{
    // Subclasses need to override this method to determine if they have received all the custom information requests needed
    for (NSString *s in self.frequencyTextList) {
        if ([s isEqualToString:@""]) {
            return NO;
        }
    }
    return YES;
}

- (void)configureRemoteComponents
{
    // Subclasses of ServerConfigHelper need to override this method to copy completed Server Component Configuration over to the RemoteServer
    
    // Create the Source Objects in the local source list
    [self addAnthemSourceWithName:@"CD" Value:@"0" enabled:@"Y"];
    [self addAnthemSourceWithName:@"2-Ch BAH" Value:@"1" enabled:@"Y"];
    [self addAnthemSourceWithName:@"6-Ch S/E" Value:@"2" enabled:@"Y"];
    [self addAnthemSourceWithName:@"Tape" Value:@"3" enabled:@"Y"];
    [self addAnthemSourceWithName:@"Tuner" Value:@"4" enabled:@"Y"];
    [self addAnthemSourceWithName:@"DVD1" Value:@"5" enabled:@"Y"];
    [self addAnthemSourceWithName:@"TV1" Value:@"6" enabled:@"Y"];
    [self addAnthemSourceWithName:@"Sat1" Value:@"7" enabled:@"Y"];
    [self addAnthemSourceWithName:@"VCR" Value:@"8" enabled:@"Y"];
    [self addAnthemSourceWithName:@"Aux" Value:@"9" enabled:@"Y"];
    [self addAnthemSourceWithName:@"DVD2" Value:@"d" enabled:@"N"];
    [self addAnthemSourceWithName:@"DVD3" Value:@"e" enabled:@"N"];
    [self addAnthemSourceWithName:@"DVD4" Value:@"f" enabled:@"N"];
    [self addAnthemSourceWithName:@"TV2" Value:@"g" enabled:@"N"];
    [self addAnthemSourceWithName:@"TV3" Value:@"h" enabled:@"N"];
    [self addAnthemSourceWithName:@"TV4" Value:@"i" enabled:@"N"];
    [self addAnthemSourceWithName:@"Sat2" Value:@"j" enabled:@"N"];
    
    // Process and load Source Information
    int sourcesFoundCount = 0;
    int sourcesEnabledCount = 0;
    for (Source *s in self.sourceList) {
        if (s.name) {
            [self.server addSource:s];
            sourcesFoundCount++;
            if (s.enabled.boolValue) {
                sourcesEnabledCount++;
            }
        }
    }
    
    [self.serverSetupController postString:[NSString stringWithFormat:@"...%d sources setup, %d sources enabled", sourcesFoundCount, sourcesEnabledCount]
                                        to:PostStringDestinationLog|PostStringDestinationFeedback];
    
    // Create a Source "c" for the "Copy Main" Source
    Command *c = [[Command alloc] initWithVariable:@"S" parameterPrefix:@"" parameter:@"M"];
    Source *copyMainSource = [[Source alloc] initWithName:@"Copy Main" variable:@"S" value:@"M" sourceCommand:c enabled:@"Yes"];
    
    // Process and load Local Preset Information
    self.tuner.stations = [[NSMutableArray alloc] init];
    for (NSString *s in self.frequencyTextList) {
        if (![s isEqualToString:@""]) {
            TunerStationAnthemAVM *station = [[TunerStationAnthemAVM alloc] initWithFrequencyText:s];
            [self.tuner.stations addObject:station];
        }
    }
    [self.tuner removeStationDuplicates];
    
    if ([self.tuner.stations count] > 0) {
        [self.serverSetupController postString:[NSString stringWithFormat:@"...%lu app tuner presets copied from processor", (unsigned long)[self.tuner.stations count]]
                                        to:PostStringDestinationLog|PostStringDestinationFeedback];
    } else {
        // We need to have at least on preset loaded
        TunerStationAnthemAVM *station = [[TunerStationAnthemAVM alloc] initWithFrequencyText:@"92.5 FM"];
        [self.tuner.stations addObject:station];
    }
    [self.serverSetupController postString:[NSString stringWithFormat:@"...app tuner presets can be changed in Zone settings"]
                                        to:PostStringDestinationLog|PostStringDestinationFeedback];
    
    // Process and load our Components
    if (self.tuner) {
        self.tuner.nameShort = [NSString stringWithFormat:@"%@ Tuner", self.server.nameShort];
        self.tuner.nameLong = [NSString stringWithFormat:@"%@ Tuner", self.server.model];
        self.tuner.tunerPresetType = TunerPresetTypeLocal;
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
    
}

//- (void)setTunerSource
//{
//    // Extend or Override this if more sophistication is needed to find the tuner vs scanning the simple name-scanning the super class does
//}

- (void)setMainZoneSource
{
    // Subclasses need to override this method to complete settings on the min and max volume ranges
    self.server.mainZoneSourceValue = @"c";
}

- (void)setVolumeSettings
{
    // Subclasses need to override this method to complete settings on the min and max volume ranges
    [self setVolumeRangeForZone:self.zone1 withVolumeControlStatus:nil withBaseVolume:self.zone1Volume];
    [self setVolumeRangeForZone:self.zone2 withVolumeControlStatus:nil withBaseVolume:self.zone2Volume];
    [self setVolumeRangeForZone:self.zone3 withVolumeControlStatus:nil withBaseVolume:self.zone3Volume];
}

- (void)sendRequestForStatus
{
    // Subclasses need to override this method to send a message to all RemoteComponents to send a request
    // for Status (all Tuners and Zones), to extend that is supported by the Brand-Model
    [self.tuner sendRequestForStatus];
    [self.zone1 sendRequestForStatus];
    [self.zone2 sendRequestForStatus];
    [self.zone3 sendRequestForStatus];
}


#pragma mark - Local Helpers

- (void)configureTunerAnthemAVM:(RemoteTunerAnthemAVM *)tuner
{
    tuner.frequencyStatus = [[Status alloc] initWithVariable:@"T"
                                                commandValue:@"?"];
    tuner.presetIndex = -1; // No preset set
    
    tuner.presetUpCommand = [[CommandAnthemAVMPresetUp alloc] init];
    tuner.presetDownCommand = [[CommandAnthemAVMPresetDown alloc] init];
    
    // Create a set of the Stati for fast enumeration
    tuner.statusSet = [[NSSet alloc] initWithObjects:tuner.frequencyStatus,
                                                           nil];
    tuner.mustRequestStatus = YES;
}

- (void)configureZoneAnthemAVM:(RemoteZoneAnthemAVM *)zone
  withVolumeCommandVariable:(NSString *)volumeCommandVariable
{
    zone.powerStatus    = [[Status alloc] initWithVariable:@"P"
                                              commandValue:@"?"];
    zone.powerStatus.state = RemoteStatusStateOff;
    zone.powerOnCommand  = [[Command alloc] initWithVariable:@"P"
                                          parameterPrefix:@""
                                                parameter:@"1"];
    zone.powerOffCommand = [[Command alloc] initWithVariable:@"P"
                                          parameterPrefix:@""
                                                parameter:@"0"];
    
    zone.modeStatus        = nil;
    zone.modeZoneCommand   = nil;
    zone.modeRecordCommand = nil;
    
    zone.volumeControlFixed = nil;
    zone.volumeStatus    = [[Status alloc] initWithVariable:volumeCommandVariable
                                               commandValue:@"?"]; // An array of Volume commands should be setup
    zone.usesVolumeHalfSteps = YES;
    zone.volumeCommandTemplate = [[Command alloc] initWithVariable:volumeCommandVariable
                                                parameterPrefix:@""
                                                      parameter:@""]; // An array of Volume commands should be setup too
    
    zone.muteStatus      = [[Status alloc] initWithVariable:@"M"        // Anthem does not have a status capability for mute on pre-MRX AVM
                                               commandValue:@"?"];      // Set it up or the mute button itself will be hidden
    zone.muteStatus.state  = RemoteStatusStateOff;
    zone.muteOnCommand   = [[Command alloc] initWithVariable:@"M"
                                          parameterPrefix:@""
                                                parameter:@"1"];
    zone.muteOffCommand  = [[Command alloc] initWithVariable:@"M"
                                          parameterPrefix:@""
                                                parameter:@"0"];
    
    zone.sourceStatus    = [[Status alloc] initWithVariable:@"S"
                                               commandValue:@"?"];
    
    // Create a set of the Stati for fast enumeration later
    zone.statusSet = [[NSSet alloc] initWithObjects:zone.powerStatus,
                                                    zone.volumeStatus,
                                                    zone.sourceStatus,
                                                 // zone.muteStatus,     // Anthem does not have a status capability for mute on pre-MRX AVM
                                                    nil];
    zone.mustRequestStatus = YES;
    
}

-(void)addAnthemSourceWithName:(NSString *)name
                         Value:(NSString *)value
                       enabled:(NSString *)enabled
{
    Command *c = [[Command alloc] initWithVariable:@"S"
                                parameterPrefix:@""
                                      parameter:value];
    Source *s = [[Source alloc] initWithName:name
                                    variable:@"S"
                                       value:value
                               sourceCommand:c
                                     enabled:enabled];
    [self.sourceList addObject:s];
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
//            if (self.mustRequestSourceInfo) {
//                [self sendRequestForSourceInfo];
//            }
            if (self.mustRequestOtherCustomInfo) {
                [self sendRequestForOtherCustomInfo];
            }
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
        
        NSString *tunerOverrideIP = [demoServer objectForKey:@"tunerOverride.IP"];
        if (![tunerOverrideIP isEqualToString:@""]) {
            
            // Disable the local Tuner Source
            Source *s = self.sourceList[4]; s.enabled = @"N";
            
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
            
        }
        
        // Custom Source Settings (all of these can be changed on Zone Settings View)
        if ([self.sourceList count] >= 17) {
            Source *s = self.sourceList[0]; s.name = @"HTPC";
            s = self.sourceList[1];         s.name = @"XBOX";
            s = self.sourceList[2];         s.name = @"Wii";
            s = self.sourceList[3];         s.name = @"Rack Tuner";
            self.server.tunerSourceValue = s.value;
            s = self.sourceList[5];         s.name = @"BLURay";
            s = self.sourceList[6];         s.name = @"TV";
            s = self.sourceList[7];         s.name = @"TV-Music";
            s = self.sourceList[8];         s.name = @"Airplay";
            s = self.sourceList[9];         s.name = @"Echo";
        }
        
    }
       
}

@end
