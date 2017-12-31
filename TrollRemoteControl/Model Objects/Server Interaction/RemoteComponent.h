//
//  RemoteComponent.h
//  TrollRemoteControl
//
//  Created by Pete Maiser on 7/31/16.
//  Copyright © 2016 Pete Maiser. All rights reserved.
//

#import <Foundation/Foundation.h>
@class RemoteServer;

@interface RemoteComponent : NSObject

@property (nonatomic, readonly, strong) NSUUID *serverUUID;
@property (nonatomic, readonly, strong) RemoteServer *server;

@property (nonatomic, copy) NSString *logFile;

@property (nonatomic, copy) NSString *prefixValue;
@property (nonatomic, copy) NSString *nameShort;
@property (nonatomic, copy) NSString *nameLong;
@property (nonatomic, strong)  NSSet *statusSet;    // Enables the creation of a set of status parameters to check when Strings are returned from the server
@property (nonatomic) BOOL mustRequestStatus;       // Set to Yes if this component is ~shy and subclasses need to request status updates after every command

- (void)setServerAsUUID:(NSUUID *)serverUUID;

- (void)sendRequestForStatus;

- (void)handleString:(NSString *)string             // Subclasses should generally implement this
          fromServer:(RemoteServer *)server;

- (void)logString:(NSString *)str;

// Archiving
- (void) encodeWithCoder:( NSCoder *) aCoder;
- (instancetype) initWithCoder:( NSCoder *) aDecoder;

// Version number to be saved in archive so that future model changes can be
// made backwards-compatible with old versions.
@property (nonatomic) NSUInteger modelObjectVersion;

@end
