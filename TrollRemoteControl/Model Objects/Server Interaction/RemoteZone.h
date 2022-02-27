//
//  RemoteZone.h
//  RemoteServerMonitor, TrollRemoteControl
//
//  Created by Pete Maiser on 1/2/16.
//  Copyright © 2016 Pete Maiser. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RemoteComponent.h"
@class Source;
@class Status;
@class Command;

@interface RemoteZone : RemoteComponent <NSSecureCoding>

@property (nonatomic, readonly, strong) NSUUID *zoneUUID;
@property (nonatomic, strong) NSUUID *tunerOverrideZoneUUID;

@property (nonatomic) Status *powerStatus;
@property (nonatomic) Command *powerOnCommand;
@property (nonatomic) Command *powerOffCommand;
@property (nonatomic) NSString *customPostPowerOnString;
@property (nonatomic) NSString *customPostPowerOffString;
@property BOOL isHidden;

@property BOOL isDynamicZoneCapable;
@property BOOL isDynamicZone;
@property (nonatomic) Status *modeStatus;
@property (nonatomic) Command *modeZoneCommand;
@property (nonatomic) Command *modeRecordCommand;

@property (nonatomic) Status *volumeControlFixed;
@property (nonatomic) Status *volumeStatus;
@property (nonatomic) Command *volumeCommandTemplate;
@property (nonatomic) BOOL usesVolumeHalfSteps;
@property (nonatomic) NSMutableArray *volumeCommands;

@property (nonatomic) Status *muteStatus;
@property (nonatomic) Command *muteOnCommand;
@property (nonatomic) Command *muteOffCommand;

@property (nonatomic) Status *sourceStatus;
@property (nonatomic) NSArray *sourceList;


- (instancetype)initZoneWithPrefixValue:(NSString *)prefixValue;

// Zone-specific sources can be added to the Server Source List - for example for "Copy Main" sources
@property (nonatomic) NSMutableArray *zoneSourceList;
- (void)addZoneSource:(Source *)source;

@end
