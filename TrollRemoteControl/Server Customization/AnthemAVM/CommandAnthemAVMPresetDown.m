//
//  CommandAnthemAVMPresetDown.m
//  DTrol
//
//  Created by Pete Maiser on 12/9/17.
//  Copyright © 2017 Pete Maiser. All rights reserved.
//

#import "CommandAnthemAVMPresetDown.h"
#import "RemoteServer.h"
#import "RemoteTunerList.h"
#import "RemoteTunerAnthemAVM.h"
#import "TunerStation.h"

@implementation CommandAnthemAVMPresetDown

// Override sendCommandToServer:withPrefix: to pull the previous station from the stations list and send the command for it.

- (void)sendCommandToServer:(RemoteServer *)server
                 withPrefix:(NSString *)prefix
{
    RemoteTunerAnthemAVM *tuner = (RemoteTunerAnthemAVM *)[[RemoteTunerList sharedList] getTunerWithServerUUID:server.serverUUID];
    NSInteger currentPresetIndex = tuner.presetIndex;
    
    NSInteger nextPresetIndex = 0;
    if ( (currentPresetIndex < 0) ||
         (currentPresetIndex > [tuner.stations count]) )
    {
        nextPresetIndex = 0;
    } else if (currentPresetIndex == 0) {
        nextPresetIndex = [tuner.stations count]-1;
    } else if (currentPresetIndex > 0) {
        nextPresetIndex = currentPresetIndex-1;
    }
    
    TunerStation *station = tuner.stations[nextPresetIndex];
    [station sendStationCommandToServer:server];
}
@end
