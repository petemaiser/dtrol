//
//  RemoteServer.h
//  RemoteServerMonitor, TrollRemoteControl
//
//  Created by Pete Maiser on 1/2/16.
//  Copyright © 2016 Pete Maiser. All rights reserved.
//

#import <Foundation/Foundation.h>
@class RemoteTuner;
@class Source;

@interface RemoteServer : NSObject <NSStreamDelegate, NSSecureCoding>

@property (nonatomic, readonly, strong) NSUUID *serverUUID;
@property BOOL isConnected;
@property (nonatomic, readonly,  strong) NSDate *dateCreated;

@property (nonatomic, copy) NSString *IP;
@property (nonatomic) uint port;
@property (nonatomic, copy) NSString *lineTerminationString;
@property BOOL treatSpaceAsLineTermination;

@property (nonatomic, copy) NSString *logFile;

@property (nonatomic, copy) NSString *model;
@property (nonatomic, copy) NSString *nameShort;
@property (nonatomic, copy) NSString *address;
@property (nonatomic, readonly) NSString *nameLong;

@property (nonatomic, readonly) NSArray *sourceList;
@property (nonatomic, readonly) NSArray *sourceListAll;
@property (nonatomic) NSString *tunerSourceValue;
@property (nonatomic) NSString *mainZoneSourceValue;
@property (nonatomic) NSString *autoOnSourceValue;
- (void)addSource:(Source *)source;

@property (nonatomic) NSString *customIfString;             // Monitor for this string as an "If".  Execute "Then" string when "If" is observed.
@property (nonatomic) NSString *customThenString;           // Execute "Then" string when "If" is observed.

@property (nonatomic, copy) void (^callbackBlock)(NSString *);
- (void)addBlockForIncomingStrings:(void (^)(NSString *))callbackBlock;
- (void)removeBlockForIncomingStrings:(void (^)(NSString *))callbackBlock;

+ (RemoteServer *)createServerWithIP:(NSString *)serverIP
                                port:(uint)serverPort
               lineTerminationString:(NSString *)termString;

- (void)openStreams;
- (void)closeStreams;

- (void)sendString:(NSString *)str;

- (BOOL)streamsReady;
- (BOOL)streamsNeedOpen;

#define StreamsReadyNotificationString @"StreamsReady"
#define StreamClosedNotificationString @"StreamClosed"
#define StreamErrorNotificationString @"StreamError"
#define StreamNewDataNotificationString @"StreamNewData"

@end
