//
//  RemoteTunerAnthemAVM.m
//  DTrol
//
//  Created by Pete Maiser on 11/13/17.
//  Copyright © 2017 Pete Maiser. All rights reserved.
//

#import "RemoteTunerAnthemAVM.h"
#import "RemoteServer.h"
#import "RemoteZoneAnthemAVM.h"
#import "RemoteZoneList.h"
#import "TunerStation.h"

@implementation RemoteTunerAnthemAVM

// For AnthemAVM Zone and Tuner, have each send a request for status for each.
// This is in effect a cheap attempt at polling...anytime we request any status we will request the whole status
- (void)sendRequestForStatus
{
    RemoteZoneAnthemAVM *zone = (RemoteZoneAnthemAVM *)[[RemoteZoneList sharedList] getZoneWithServerUUID:self.serverUUID];
    [zone sendRequestForStatusAthemAVMZone];
    [self sendRequestForStatusAthemAVMTuner];
}

- (void) sendRequestForStatusAthemAVMTuner
{
    [super sendRequestForStatus];
}

- (NSString *)presetText
{
    // See if any local presents match
    for (int i=0; i < [self.stations count]; i++) {
        TunerStation *station = self.stations[i];
        if ([station.frequencyText isEqualToString:self.frequencyText]) {
            return [NSString stringWithFormat:@"%d", i + 1];
        }
    }
    return @"";
}

- (void)handleString:(NSString *)string
          fromServer:(RemoteServer *)server
{
    [super handleString:string fromServer:server];
    
    if ([self.serverUUID.UUIDString isEqualToString:server.serverUUID.UUIDString]) {
        
        if (([string hasPrefix:self.prefixValue]) &&
            (string.length > 3) &&
            ([string characterAtIndex:2] == 'T'))
        {
            // Record the status change
            NSString *frequencyNumberText = [[string substringFromIndex:3] stringByReplacingOccurrencesOfString:@" " withString:@""];
            
            if ([string hasPrefix:@"TFT"]) {
                self.frequencyText = [NSString stringWithFormat:@"%@ FM", frequencyNumberText];
            } else if ([string hasPrefix:@"TAT"]) {
                self.frequencyText = [NSString stringWithFormat:@"%@ AM", frequencyNumberText];
            }
            
            // See if any local presents match
            self.presetIndex = -1;
            for (int i=0; i < [self.stations count]; i++) {
                TunerStation *station = self.stations[i];
                if ([station.frequencyText isEqualToString:self.frequencyText]) {
                    self.presetIndex = i;
                    break;
                }
            }
            
            [self logString:[NSString stringWithFormat:@"PROCESSED (%@):  %@ is %@", self.nameShort, self.prefixValue, self.frequencyText ]];
            
        }
    }
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.frequencyStatus forKey:@"frequencyStatus"];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        _frequencyStatus = [aDecoder decodeObjectForKey:@"frequencyStatus"];
    }
    return self;
}

@end
