//
//  RemoteTuner.m
//  RemoteServerMonitor, TrollRemoteControl
//
//  Created by Pete Maiser on 1/2/16.
//  Copyright © 2016 Pete Maiser. All rights reserved.
//

#import "RemoteTuner.h"
#import "RemoteServer.h"
#import "TunerStation.h"
#import "TunerStationAnthemAVM.h"

@implementation RemoteTuner

- (instancetype)init
{
    self = [super init];
 
    // Set default values
    if (self ) {
        self.nameShort = @"TN";
        self.nameLong = @"Tuner";
        self.frequencyText = @"";
        self.presetText = @"";
        self.tunerPresetType = TunerPresetTypeRemote;
        self.stations = nil;
    }
    return self;
}

- (instancetype)initTunerWithPrefixValue:(NSString *)prefixValue
{
    self = [self init];
    if (self) {
        self.prefixValue = prefixValue;
    }
    return self;
}

- (void)handleString:(NSString *)string
          fromServer:(RemoteServer *)server
{    
    [super handleString:string fromServer:server];
    
    // Subclasses need to extend this method to process the Brand-Model Specific Overrides return string from the RemoteServer
}

- (void)removeStationDuplicates
{
    if (self.stations) {
        NSMutableArray *newStations = [[NSMutableArray alloc] init];
        for (TunerStation *s in self.stations) {
            BOOL found = NO;
            for (TunerStation *ns in newStations) {
                if ([ns.frequencyText isEqualToString:s.frequencyText]) {
                    found = YES;
                }
            }
            if (!found) {
                [newStations addObject:s];
            }
        }
        [self.stations removeAllObjects];
        [self.stations addObjectsFromArray:newStations];
    }
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.frequencyText forKey:@"frequencyText"];
    [aCoder encodeObject:self.presetText forKey:@"presetText"];
    [aCoder encodeBool:self.tunerPresetType forKey:@"tunerPresetType"];
    [aCoder encodeObject:self.presetUpCommand forKey:@"presetUpCommand"];
    [aCoder encodeObject:self.presetDownCommand forKey:@"presetDownCommand"];
    [aCoder encodeObject:self.stations forKey:@"stations"];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        self.frequencyText = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"frequencyText"];
        self.presetText = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"presetText"];
        self.tunerPresetType = [aDecoder decodeBoolForKey:@"tunerPresetType"];
        self.presetUpCommand = [aDecoder decodeObjectOfClass:[Command class] forKey:@"presetUpCommand"];
        self.presetDownCommand = [aDecoder decodeObjectOfClass:[Command class] forKey:@"presetDownCommand"];
        NSSet *classes = [NSSet setWithObjects:[NSMutableArray class]
                          ,[TunerStation class]
                          ,[TunerStationAnthemAVM class]
                          ,[NSString class]
                          ,nil];
        self.stations = [aDecoder decodeObjectOfClasses:classes forKey:@"stations"];
    }
    
    return self;
}

+ (BOOL)supportsSecureCoding
{
    return YES;
}

@end
