//
//  RemoteServerList.h
//  RemoteServerMonitor, TrollRemoteControl
//
//  Created by Pete Maiser on 1/3/16.
//  Copyright © 2016 Pete Maiser. All rights reserved.
//

#import <Foundation/Foundation.h>
@class RemoteServer;

@interface RemoteServerList : NSObject

@property (nonatomic, readonly) NSArray *servers;

+ (instancetype)sharedList;

- (void)addServer:(RemoteServer *)server;
- (void)deleteServer:(RemoteServer *)server;
- (void)moveItemAtIndex:(NSUInteger)fromIndex
                toIndex:(NSUInteger)toIndex;
- (RemoteServer *)getServerWithUUID:(NSUUID *)uuid;

- (BOOL)saveServers;
            

@end
