//
//  RemoteZone.m
//  RemoteServerMonitor, TrollRemoteControl
//
//  Created by Pete Maiser on 1/2/16.
//  Copyright © 2016 Pete Maiser. All rights reserved.
//

#import "RemoteZone.h"
#import "RemoteServer.h"
#import "Source.h"

@interface RemoteZone ()

@end

@implementation RemoteZone

- (instancetype)init
{
    self = [super init];
    
    // Set default values
    if (self) {
        self.nameShort = @"Z?";
        self.nameLong = @"";
        self.customPostPowerOnString = @"";
        self.customPostPowerOffString = @"";
        self.isDynamicZoneCapable = NO;
        self.isDynamicZone = NO;
        self.volumeCommandTemplate = nil;
        self.usesVolumeHalfSteps = NO;
        self.zoneSourceList = nil;
    }
    return self;
}

- (instancetype)initZoneWithPrefixValue:(NSString *)prefixValue
{
    self = [self init];
    if (self) {
        self.prefixValue = prefixValue;
    }
    return self;
}

- (void)addZoneSource:(Source *)source
{
    if (self.zoneSourceList) {
        [self.zoneSourceList addObject:source];
    } else {
        self.zoneSourceList = [[NSMutableArray alloc] initWithObjects:source, nil];
    }
}

- (NSArray *)sourceList
{
    //Override the getter of the array to return a copy of the remote server sources, with any zone-specific sources added
    NSMutableArray *sourceList = nil;
    
    if (self.server.sourceList) {
        sourceList = [[NSMutableArray alloc] initWithArray:self.server.sourceList];
        for (Source *s in self.zoneSourceList) {
            [sourceList addObject:s];
        }
    } else if (self.zoneSourceList) {
        sourceList = [self.zoneSourceList copy];
    }
    
    return sourceList;
}

- (void)handleString:(NSString *)string
          fromServer:(RemoteServer *)server
{
    [super handleString:string fromServer:server];
    
    // Subclasses need to extend this method to process the Brand-Model Specific Overrides return string from the RemoteServer
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.powerStatus forKey:@"powerStatus"];
    [aCoder encodeObject:self.powerOnCommand forKey:@"powerOnCommand"];
    [aCoder encodeObject:self.powerOffCommand forKey:@"powerOffCommand"];
    [aCoder encodeObject:self.customPostPowerOnString forKey:@"customPostPowerOnString"];
    [aCoder encodeObject:self.customPostPowerOffString forKey:@"customPostPowerOffString"];
    [aCoder encodeObject:self.modeStatus forKey:@"modeStatus"];
    [aCoder encodeObject:self.modeZoneCommand forKey:@"modeZoneCommand"];
    [aCoder encodeObject:self.modeRecordCommand forKey:@"modeRecordCommand"];
    [aCoder encodeBool:self.isDynamicZoneCapable forKey:@"isDynamicZoneCapable"];
    [aCoder encodeBool:self.isDynamicZone forKey:@"isDynamicZone"];
    [aCoder encodeObject:self.volumeControlFixed forKey:@"volumeControlFixed"];
    [aCoder encodeObject:self.volumeStatus forKey:@"volumeStatus"];
    [aCoder encodeObject:self.volumeCommandTemplate forKey:@"volumeCommandTemplate"];
    [aCoder encodeBool:self.usesVolumeHalfSteps forKey:@"usesVolumeHalfSteps"];
    [aCoder encodeObject:self.volumeCommands forKey:@"volumeCommands"];
    [aCoder encodeObject:self.muteStatus forKey:@"muteStatus"];
    [aCoder encodeObject:self.muteOnCommand forKey:@"muteOnCommand"];
    [aCoder encodeObject:self.muteOffCommand forKey:@"muteOffCommand"];
    [aCoder encodeObject:self.sourceStatus forKey:@"sourceStatus"];
    [aCoder encodeObject:self.zoneSourceList forKey:@"zoneSourceList"];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        self.powerStatus = [aDecoder decodeObjectForKey:@"powerStatus"];
        self.powerOnCommand = [aDecoder decodeObjectForKey:@"powerOnCommand"];
        self.powerOffCommand = [aDecoder decodeObjectForKey:@"powerOffCommand"];
        self.customPostPowerOnString = [aDecoder decodeObjectForKey:@"customPostPowerOnString"];
        self.customPostPowerOffString = [aDecoder decodeObjectForKey:@"customPostPowerOffString"];
        self.modeStatus = [aDecoder decodeObjectForKey:@"modeStatus"];
        self.modeZoneCommand = [aDecoder decodeObjectForKey:@"modeZoneCommand"];
        self.modeRecordCommand = [aDecoder decodeObjectForKey:@"modeRecordCommand"];
        self.isDynamicZoneCapable = [aDecoder decodeBoolForKey:@"isDynamicZoneCapable"];
        self.isDynamicZone = [aDecoder decodeBoolForKey:@"isDynamicZone"];
        self.volumeControlFixed = [aDecoder decodeObjectForKey:@"volumeControlFixed"];
        self.volumeStatus = [aDecoder decodeObjectForKey:@"volumeStatus"];
        self.volumeCommandTemplate = [aDecoder decodeObjectForKey:@"volumeCommandTemplate"];
        self.usesVolumeHalfSteps = [aDecoder decodeBoolForKey:@"usesVolumeHalfSteps"];
        self.volumeCommands = [aDecoder decodeObjectForKey:@"volumeCommands"];
        self.muteStatus = [aDecoder decodeObjectForKey:@"muteStatus"];
        self.muteOnCommand = [aDecoder decodeObjectForKey:@"muteOnCommand"];
        self.muteOffCommand = [aDecoder decodeObjectForKey:@"muteOffCommand"];
        self.sourceStatus = [aDecoder decodeObjectForKey:@"sourceStatus"];
        self.zoneSourceList = [aDecoder decodeObjectForKey:@"zoneSourceList"];
    }
    
    return self;
}

@end
