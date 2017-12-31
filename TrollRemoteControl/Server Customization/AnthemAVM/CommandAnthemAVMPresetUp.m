//
//  CommandAnthemAVMPresetUp.m
//  DTrol
//
//  Created by Pete Maiser on 12/9/17.
//  Copyright © 2017 Pete Maiser. All rights reserved.
//

#import "CommandAnthemAVMPresetUp.h"
#import "RemoteServer.h"
#import "RemoteTunerList.h"
#import "RemoteTunerAnthemAVM.h"
#import "TunerStation.h"

@implementation CommandAnthemAVMPresetUp

// Override sendCommandToServer:withPrefix: to pull the next station from the stations list and send the command for it.

- (void)sendCommandToServer:(RemoteServer *)server
                 withPrefix:(NSString *)prefix
{
    RemoteTunerAnthemAVM *tuner = (RemoteTunerAnthemAVM *)[[RemoteTunerList sharedList] getTunerWithServerUUID:server.serverUUID];
    NSInteger currentPresetIndex = tuner.presetIndex;
    
    NSInteger nextPresetIndex = 0;
    if (currentPresetIndex < ([tuner.stations count]-1)) {
        nextPresetIndex = currentPresetIndex+1;
    }
    
    TunerStation *station = tuner.stations[nextPresetIndex];
    [station sendStationCommandToServer:server];
}

@end
