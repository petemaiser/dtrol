//
//  RemoteZoneNAD.m
//  DTrol
//
//  Created by Pete Maiser on 11/13/17.
//  Copyright © 2017 Pete Maiser. All rights reserved.
//

#import "RemoteZoneNAD.h"
#import "RemoteServer.h"
#import "Command.h"
#import "Status.h"

@implementation RemoteZoneNAD

- (instancetype)initWithRemoteZone:(RemoteZone *)remoteZone
{
    self = [super init];

    if (self) {

        // RemoteComponent Items
        self.logFile = remoteZone.logFile;
        self.nameShort = remoteZone.nameShort;
        self.nameLong = remoteZone.nameLong;
        self.prefixValue = remoteZone.prefixValue;
        self.statusSet = remoteZone.statusSet;
        self.mustRequestStatus = remoteZone.mustRequestStatus;
        self.modelObjectVersion = remoteZone.modelObjectVersion;
        [self setServerAsUUID:remoteZone.serverUUID];
        
        // RemoteZone Items
        self.powerStatus = remoteZone.powerStatus;
        self.powerOnCommand = remoteZone.powerOnCommand;
        self.powerOffCommand = remoteZone.powerOffCommand;
        self.customPostPowerOnString = remoteZone.customPostPowerOnString;
        self.customPostPowerOffString = remoteZone.customPostPowerOffString;
        self.modeStatus = remoteZone.modeStatus;
        self.modeZoneCommand = remoteZone.modeZoneCommand;
        self.modeRecordCommand = remoteZone.modeRecordCommand;
        self.isDynamicZoneCapable = remoteZone.isDynamicZoneCapable;
        self.isDynamicZone = remoteZone.isDynamicZone;
        self.volumeControlFixed = remoteZone.volumeControlFixed;
        self.volumeStatus = remoteZone.volumeStatus;
        self.volumeCommandTemplate = remoteZone.volumeCommandTemplate;
        self.usesVolumeHalfSteps = remoteZone.usesVolumeHalfSteps;
        self.volumeCommands = remoteZone.volumeCommands;
        self.muteStatus = remoteZone.muteStatus;
        self.muteOnCommand = remoteZone.muteOnCommand;
        self.muteOffCommand = remoteZone.muteOffCommand;
        self.sourceStatus = remoteZone.sourceStatus;
        self.zoneSourceList = remoteZone.zoneSourceList;
        
    }
    return self;
}

- (void)handleString:(NSString *)string
          fromServer:(RemoteServer *)server
{
    [super handleString:string fromServer:server];
    
    if ([self.serverUUID.UUIDString isEqualToString:server.serverUUID.UUIDString]) {
        
        if ([string hasPrefix:self.prefixValue]) {
                
            NSArray *responseStringComponents = [string componentsSeparatedByString:@"="];
            
            if ([responseStringComponents count] > 1) {
                
                NSString *value = responseStringComponents[1];
                
                NSRange variableRange = [responseStringComponents[0] rangeOfString:@"."];
                NSString *variable = [responseStringComponents[0] substringFromIndex:(variableRange.location)];
                
                for (Status *zoneStatus in self.statusSet) {
                    
                    if ([variable isEqualToString:zoneStatus.variable]) {
                        
                        // Update the status
                        zoneStatus.value = value;
                        [self logString:[NSString stringWithFormat:@"PROCESSED (%@):  %@%@ is %@", self.nameShort, self.prefixValue, variable, value]];
                        
                        // Check if the Status has a state, and if so set it
                        if (zoneStatus.state != RemoteStatusStateNone) {
                            if ([value isEqualToString:@"On"]) {
                                zoneStatus.state = RemoteStatusStateOn;
                            } else if ([value isEqualToString:@"Off"]) {
                                zoneStatus.state = RemoteStatusStateOff;
                            } else if ([variable isEqualToString:@".VolumeControl"]) {
                                if ([value isEqualToString:@"Fixed"]) {
                                    zoneStatus.state = RemoteStatusStateOn;
                                } else {
                                    zoneStatus.state = RemoteStatusStateOff;
                                }
                            }
                        }
                    }
                }
            }
            
        }
    }
}

@end
