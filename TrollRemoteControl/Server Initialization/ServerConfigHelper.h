//
//  ServerConfigHelper.h
//
//  Created by Pete Maiser on 2/26/17.
//  Copyright © 2017 Pete Maiser. All rights reserved.
//
//  This class is used to gather all data required to setup a RemoteServer and all of its
//  RemoteComponents (i.e. all Tuners and all Zones).  It must be subclassed based on the
//  particular make/model of Receiver or Processor.
//
//  This program comes with ABSOLUTELY NO WARRANTY.
//  You are welcome to redistribute this software under certain conditions; see the included LICENSE file for details.
//

#import <Foundation/Foundation.h>
#import "ServerSetupController.h"
@class RemoteZone;
@class ServerSetupController;

@interface ServerConfigHelper : NSObject            // Helper object to interrogate servers to build settings as part of app configuration
                                                    // This object should be subclassed to implement specific device families or protocols
                                                    // e.g. for NAD, Anthem pre-MRX, etc.

@property (weak, nonatomic) ServerSetupController *serverSetupController;

// Initializers
- (instancetype)initWithServerSetupController:(ServerSetupController *)ssc;  // Subclasses should generally extend this for any additional initialization

// Server Configuration Process
- (void)startServerConfiguration;                       // Start the config process by setting-up the structure and then starting Interrogation
                                                        // Interrogation sends requests to the Server to learn about current state
- (void)checkServerInterrogationStatus;                 // Check on Interrogation status and send a notification if complete
- (void)abortServerConfiguration;                       // Stop the config process and clean-up
- (void)finishServerConfiguration;                      // Called when Interrogation is complete (or we are giving-up) to finish the Configuration process

// Volume Settings-Configuration Helpers
- (void)setVolumeRangeForZone:(RemoteZone *)zone        // Help set volume
      withVolumeControlStatus:(NSString *)volumeControlStatus
               withBaseVolume:(NSString *)baseVolume;
- (void)setVolumeRangeForZone:(RemoteZone *)zone
                    fromValue:(int)fromValue
                      toValue:(int)toValue;

// Demo Mode
@property (nonatomic) NSInteger demoMode;
@property BOOL mustRequestSourceInfo;       // Helper property, determines if info should be requested about Sources
@property BOOL mustRequestVolumeInfo;       // Helper property, determines if info should be requested for volume from the Zones
@property BOOL mustRequestOtherCustomInfo;  // Helper property, determines if other custom info should be requested
- (void)processDemoMode:(NSInteger)demoMode;

@end
