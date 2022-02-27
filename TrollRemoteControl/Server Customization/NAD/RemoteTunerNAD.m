//
//  RemoteTunerNAD.m
//  DTrol
//
//  Created by Pete Maiser on 11/13/17.
//  Copyright © 2017 Pete Maiser. All rights reserved.
//

#import "RemoteTunerNAD.h"
#import "ServerConfigHelperNAD.h"
#import "RemoteServer.h"
#import "Command.h"
#import "Status.h"

@implementation RemoteTunerNAD

- (instancetype)initWithRemoteTuner:(RemoteTuner *)remoteTuner
{
    self = [super init];
    
    if (self) {
        
        // RemoteComponent Items
        self.logFile = remoteTuner.logFile;
        self.nameShort = remoteTuner.nameShort;
        self.nameLong = remoteTuner.nameLong;
        self.prefixValue = remoteTuner.prefixValue;
        self.statusSet = remoteTuner.statusSet;
        self.mustRequestStatus = remoteTuner.mustRequestStatus;
        self.modelObjectVersion = remoteTuner.modelObjectVersion;
        [self setServerAsUUID:remoteTuner.serverUUID];
        
        // RemoteTuner Items
        self.frequencyText = remoteTuner.frequencyText;
        self.presetText = remoteTuner.presetText;
        self.tunerPresetType = remoteTuner.tunerPresetType;
        self.presetUpCommand = remoteTuner.presetUpCommand;
        self.presetDownCommand = remoteTuner.presetUpCommand;
        self.stations = remoteTuner.stations;
        
        // NAD Tuner particulars
        ServerConfigHelperNAD *schNAD = [[ServerConfigHelperNAD alloc] init];
        [schNAD configureTunerNAD:self];
    }
    return self;
}

- (NSString *)frequencyText
{
    //Override the getter to create frequency text
    if (self.AMFrequencyStatus.state) {
        return [self.AMFrequencyStatus.value stringByAppendingString:@" AM"];
    } else {
        return [self.FMFrequencyStatus.value stringByAppendingString:@" FM"];
    }
}

- (NSString *)presetText
{
    //Override the getter to create preset text
    return (self.presetStatus.value);
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
                
                for (Status *tunerStatus in self.statusSet) {
                    
                    if ([variable isEqualToString:tunerStatus.variable]) {
                        
                        // Update the status
                        tunerStatus.value = value;
                        [self logString:[NSString stringWithFormat:@"PROCESSED (%@):  %@%@ is %@", self.nameShort, self.prefixValue, variable, value]];
                        
                        // Also check if this is a band status, and if so set the state on AM/FM
                        
                        if ([tunerStatus.variable isEqualToString:@".Band"]) {
                            if ([value isEqualToString:@"FM"]) {
                                self.FMFrequencyStatus.state = RemoteStatusStateOn;
                                self.AMFrequencyStatus.state = RemoteStatusStateOff;
                            } else if ([value isEqualToString:@"AM"]) {
                                self.FMFrequencyStatus.state = RemoteStatusStateOff;
                                self.AMFrequencyStatus.state = RemoteStatusStateOn;
                            } else {
                                self.FMFrequencyStatus.state = RemoteStatusStateOff;
                                self.AMFrequencyStatus.state = RemoteStatusStateOff;
                            }
                            
                        }
                    }
                }

            }
            
        }
    }
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];    
    [aCoder encodeObject:self.bandStatus forKey:@"bandStatus"];
    [aCoder encodeObject:self.AMFrequencyStatus forKey:@"AMFrequencyStatus"];
    [aCoder encodeObject:self.FMFrequencyStatus forKey:@"FMFrequencyStatus"];
    [aCoder encodeObject:self.presetStatus forKey:@"presetStatus"];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        _bandStatus = [aDecoder decodeObjectOfClass:[Status class] forKey:@"bandStatus"];
        _AMFrequencyStatus = [aDecoder decodeObjectOfClass:[Status class] forKey:@"AMFrequencyStatus"];
        _FMFrequencyStatus = [aDecoder decodeObjectOfClass:[Status class] forKey:@"FMFrequencyStatus"];
        _presetStatus =     [aDecoder decodeObjectOfClass:[Status class] forKey:@"presetStatus"];
    }
    
    return self;
}

+ (BOOL)supportsSecureCoding
{
    return YES;
}

@end
