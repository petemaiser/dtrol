//
//  ServerSetupController.h
//  DTrol
//
//  Created by Pete Maiser on 11/11/17.
//  Copyright © 2017 Pete Maiser. All rights reserved.
//

#import <Foundation/Foundation.h>
@class RemoteServer;
@class ServerFinder;
@class ServerConfigHelper;

typedef NS_ENUM(NSInteger, ServerSetupStatusType) {
    ServerSetupStatusNotConnected = 0
    ,ServerSetupStatusConnected = 1
    ,ServerSetupStatusModelSearch = 2
    ,ServerSetupStatusModelFound = 3
    ,ServerSetupStatusInnterogation = 4
    ,ServerSetupStatusInnterogationTimeOut = 5
    ,ServerSetupStatusInnterogationSuccess = 6
    ,ServerSetupStatusComplete = 7
};

@interface ServerSetupController : NSObject

@property (weak, nonatomic) RemoteServer *server;
@property (strong, nonatomic) ServerFinder *serverFinder;
@property (strong, nonatomic) ServerConfigHelper *serverConfgHelper;
@property (nonatomic) ServerSetupStatusType serverSetupStatus;

// Initialize, Startup, Abort
- (instancetype)initWithServerIP:(NSString *)serverIP
                            port:(uint)serverPort
                      identifier:(NSString *)nameShort
                          isDemo:(BOOL)isDemo;

- (void)startServerSetup;
- (void)abortServerSetup;

// User Feedback Helper
@property (nonatomic, copy) void (^feedbackBlock)(NSString *);
- (void)postString:(NSString *)string
                to:(NSUInteger)destination;
#define PostStringDestinationFeedback 1 << 0
#define PostStringDestinationLog 1 << 1

@end

// Demo Mode - fill-in placeholders if left empty
#define DemoServerPort 4999
#define DemoServerIdentifier @"TNR"
#define DemoServerIPAddress @"192.168.30.50"

// Notification Strings
#define ServerFoundNotificationString @"ServerFound"
#define ServerInterrogationCompleteNotificationString @"ServerInterrogationComplete"
#define ServerSetupCompleteNotificationString @"ServerSetupComplete"
#define ServerSetupFailNotificationString @"ServerSetupFail"
