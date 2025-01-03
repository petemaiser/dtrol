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
#import "Status.h"
#import "Command.h"

@interface RemoteZone ()

@end

@implementation RemoteZone

- (instancetype)init
{
    self = [super init];
    
    // Set default values
    if (self) {
        _zoneUUID = [[NSUUID alloc] init];
        self.tunerOverrideZoneUUID = nil;
        self.dependentZoneUUIDList = [[NSMutableArray alloc] init];
        self.nameShort = @"Z?";
        self.nameLong = @"";
        self.customPostPowerOnString = @"";
        self.customPostPowerOffString = @"";
        self.isHidden = NO;
        self.isMainZone = NO;
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
    //Override the getter of the array to return a copy of the remote server sources,
    // remove the "Copy Main" source if this is the main zone,
    // and add any zone-specific sources that exist
    NSMutableArray *sourceList = nil;
    
    if (self.server.sourceList) {
        sourceList = [[NSMutableArray alloc] initWithArray:self.server.sourceList];
        if (self.isMainZone) {
            for (Source *s in sourceList) {
                if ([s.value isEqual:self.server.mainZoneSourceValue]) {
                    [sourceList removeObject:s];
                }
            }
        }
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
    [aCoder encodeBool:self.isMainZone forKey:@"isMainZone"];
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
    [aCoder encodeObject:self.zoneUUID forKey:@"zoneUUID"];
    [aCoder encodeObject:self.tunerOverrideZoneUUID forKey:@"tunerOverrideZoneUUID"];
    [aCoder encodeBool:self.isHidden forKey:@"isHidden"];
    [aCoder encodeObject:self.dependentZoneUUIDList forKey:@"dependentZoneUUIDList"];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        
        self.powerStatus = [aDecoder decodeObjectOfClass:[Status class] forKey:@"powerStatus"];
        self.powerOnCommand = [aDecoder decodeObjectOfClass:[Command class] forKey:@"powerOnCommand"];
        self.powerOffCommand = [aDecoder decodeObjectOfClass:[Command class] forKey:@"powerOffCommand"];
        self.customPostPowerOnString = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"customPostPowerOnString"];
        self.customPostPowerOffString = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"customPostPowerOffString"];
        
        self.modeStatus =  [aDecoder decodeObjectOfClass:[Status class] forKey:@"modeStatus"];
        self.modeZoneCommand =  [aDecoder decodeObjectOfClass:[Command class] forKey:@"modeZoneCommand"];
        self.modeRecordCommand =  [aDecoder decodeObjectOfClass:[Command class] forKey:@"modeRecordCommand"];
        
        self.isMainZone = [aDecoder decodeBoolForKey:@"isMainZone"];
                
        self.isDynamicZoneCapable = [aDecoder decodeBoolForKey:@"isDynamicZoneCapable"];
        self.isDynamicZone = [aDecoder decodeBoolForKey:@"isDynamicZone"];
        
        self.volumeControlFixed =  [aDecoder decodeObjectOfClass:[Status class] forKey:@"volumeControlFixed"];
        self.volumeStatus =  [aDecoder decodeObjectOfClass:[Status class] forKey:@"volumeStatus"];
        self.volumeCommandTemplate =  [aDecoder decodeObjectOfClass:[Command class] forKey:@"volumeCommandTemplate"];
        self.usesVolumeHalfSteps = [aDecoder decodeBoolForKey:@"usesVolumeHalfSteps"];
        NSSet *classes1 = [NSSet setWithObjects:[NSMutableArray class]
                                                ,[Command class]
                                                ,[NSString class]
                                                ,nil];
        self.volumeCommands = [aDecoder decodeObjectOfClasses:classes1 forKey:@"volumeCommands"];
        
        self.muteStatus =  [aDecoder decodeObjectOfClass:[Status class] forKey:@"muteStatus"];
        self.muteOnCommand = [aDecoder decodeObjectOfClass:[Command class] forKey:@"muteOnCommand"];
        self.muteOffCommand =  [aDecoder decodeObjectOfClass:[Command class] forKey:@"muteOffCommand"];
        
        self.sourceStatus =  [aDecoder decodeObjectOfClass:[Status class] forKey:@"sourceStatus"];
        NSSet *classes2 = [NSSet setWithObjects:[NSMutableArray class]
                                                ,[Command class]
                                                ,[Source class]
                                                ,[NSString class]
                                                ,nil];
        self.zoneSourceList = [aDecoder decodeObjectOfClasses:classes2 forKey:@"zoneSourceList"];
        
        _zoneUUID = [aDecoder decodeObjectOfClass:[NSUUID class] forKey:@"zoneUUID"];
        self.tunerOverrideZoneUUID = [aDecoder decodeObjectOfClass:[NSUUID class] forKey:@"tunerOverrideZoneUUID"];
        self.isHidden = [aDecoder decodeBoolForKey:@"isHidden"];
        NSSet *classes3 = [NSSet setWithObjects:[NSMutableArray class]
                                                ,[NSUUID class]
                                                ,nil];
        self.dependentZoneUUIDList = [aDecoder decodeObjectOfClasses:classes3 forKey:@"dependentZoneUUIDList"];
    }
    
    return self;
}

+ (BOOL)supportsSecureCoding
{
    return YES;
}

@end
