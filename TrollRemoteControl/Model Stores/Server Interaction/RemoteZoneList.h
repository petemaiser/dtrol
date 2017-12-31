//
//  RemoteZoneList.h
//  RemoteServerMonitor, TrollRemoteControl
//
//  Created by Pete Maiser on 1/3/16.
//  Copyright © 2016 Pete Maiser. All rights reserved.
//

#import <Foundation/Foundation.h>
@class RemoteZone;
@class RemoteServer;

@interface RemoteZoneList : NSObject

@property (nonatomic, readonly) NSArray *zones;

+ (instancetype)sharedList;

- (void)addZone:(RemoteZone *)zone;
- (void)deleteZone:(RemoteZone *)zone;
- (void)deteleZonesWithServer:(RemoteServer *)server;
- (void)moveItemAtIndex:(NSUInteger)fromIndex
                toIndex:(NSUInteger)toIndex;

- (void)handleString:(NSString *)string
          fromServer:(RemoteServer *)server;

- (BOOL)validateServer:(RemoteServer *)server;

- (RemoteZone *)getZoneWithServerUUID:(NSUUID *)uuid;

- (BOOL)saveZones;

@end
