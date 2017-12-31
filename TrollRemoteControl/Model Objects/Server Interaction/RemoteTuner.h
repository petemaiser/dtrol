//
//  RemoteTuner.h
//  RemoteServerMonitor, TrollRemoteControl
//
//  Created by Pete Maiser on 1/2/16.
//  Copyright © 2016 Pete Maiser. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RemoteComponent.h"
#import "Command.h"

typedef NS_ENUM(NSInteger, TunerPresetType) {
     TunerPresetTypeRemote = 0                  // Typical Type, where a tuner has commands to seek through the presets
    ,TunerPresetTypeLocal = 1                   // Anthem AVM style, where preset seek is not supported.
                                                // For "Local" type we will build "Tuner Station" present capability into this app.
};

@class Status;

@interface RemoteTuner : RemoteComponent

@property (nonatomic) NSString *frequencyText;
@property (nonatomic) NSString *presetText;
@property (nonatomic) TunerPresetType tunerPresetType;

- (instancetype)initTunerWithPrefixValue:(NSString *)prefixValue;

@property (nonatomic) Command *presetUpCommand;
@property (nonatomic) Command *presetDownCommand;

// For "Local" type we will build "Tuner Station" present capability into this app.  "Remote" type will not need this.
@property (nonatomic) NSMutableArray *stations;
- (void)removeStationDuplicates;

@end
