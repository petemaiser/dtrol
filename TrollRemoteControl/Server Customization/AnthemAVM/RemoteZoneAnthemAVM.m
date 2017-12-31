//
//  RemoteZoneAnthemAVM.m
//  DTrol
//
//  Created by Pete Maiser on 11/13/17.
//  Copyright © 2017 Pete Maiser. All rights reserved.
//

#import "RemoteZoneAnthemAVM.h"
#import "RemoteServer.h"
#import "RemoteTunerAnthemAVM.h"
#import "RemoteTunerList.h"
#import "Status.h"

@implementation RemoteZoneAnthemAVM

// For AnthemAVM Zone and Tuner, have each send a request for status for each.
// This is in effect a cheap attempt at polling...anytime we request any status we will request the whole status
- (void)sendRequestForStatus
{
    RemoteTunerAnthemAVM *tuner = (RemoteTunerAnthemAVM *)[[RemoteTunerList sharedList] getTunerWithServerUUID:self.serverUUID];
    [tuner sendRequestForStatusAthemAVMTuner];
    [self sendRequestForStatusAthemAVMZone];
}

- (void) sendRequestForStatusAthemAVMZone
{
    [super sendRequestForStatus];
}

- (void)handleString:(NSString *)string
          fromServer:(RemoteServer *)server
{
    [super handleString:string fromServer:server];
    
    if ([self.serverUUID.UUIDString isEqualToString:server.serverUUID.UUIDString]) {
        
        if ([string hasPrefix:self.prefixValue]) {

            NSString *status = [string substringFromIndex:2];  // Strip out the component prefix
            NSString *variable = nil;
            NSString *value = nil;
            
            if ([status hasPrefix:@"VM"]) {
                variable = @"VM";
                value = [status substringFromIndex:2];
            }
            else if ([status hasPrefix:@"V"]) {
                variable = @"V";
                value = [status substringFromIndex:1];
            }
            else if ([status hasPrefix:@"P"]) {
                variable = @"P";
                value = [status substringFromIndex:1];
            }
            else if ([status hasPrefix:@"S"]) {
                variable = @"S";
                value = [status substringFromIndex:1];
            }
            else if ([status hasPrefix:@"M"]) {
                variable = @"M";
                value = [status substringFromIndex:1];
            }
            
            if (variable && value) {
                for (Status *zoneStatus in self.statusSet) {
                    if ([variable isEqualToString:zoneStatus.variable]) {
                        
                        // Record the status change
                        zoneStatus.value = value;
                        [self logString:[NSString stringWithFormat:@"PROCESSED (%@):  %@ %@ is %@", self.nameShort, self.prefixValue, variable, value]];
                        
                        // Check if the Status has a state, and if so set it
                        if (zoneStatus.state != RemoteStatusStateNone) {
                            if ([value isEqualToString:@"1"]) {
                                zoneStatus.state = RemoteStatusStateOn;
                            } else if ([value isEqualToString:@"0"]) {
                                zoneStatus.state = RemoteStatusStateOff;
                            }
                        }
                    }
                }
            }
        }
    }
}

@end
