//
//  RemoteTunerList.h
//  RemoteServerMonitor, TrollRemoteControl
//
//  Created by Pete Maiser on 1/3/16.
//  Copyright © 2016 Pete Maiser. All rights reserved.
//

#import <Foundation/Foundation.h>
@class RemoteTuner;
@class RemoteServer;

@interface RemoteTunerList : NSObject

@property (nonatomic, readonly) NSArray *tuners;

+ (instancetype)sharedList;
- (void)addTuner:(RemoteTuner *)tuner;
- (void)deleteTuner:(RemoteTuner *)tuner;
- (void)deteleTunersWithServer:(RemoteServer *)server;

- (void)handleString:(NSString *)string
          fromServer:(RemoteServer *)server;

- (RemoteTuner *)getTunerWithServerUUID:(NSUUID *)uuid;

- (BOOL)saveTuners;

@end
