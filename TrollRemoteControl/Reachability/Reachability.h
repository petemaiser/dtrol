//
//  Reachability.h
//
//  Pete Maiser, 9/24/2016
//

#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <netinet/in.h>

extern NSString *kReachabilityChangedNotification;

@interface Reachability : NSObject

typedef enum : NSInteger {
    NotReachable = 0,
    ReachableViaWiFi,
    ReachableViaWWAN
} NetworkStatus;

+ (instancetype)sharedReachability;


/* Start listening for reachability notifications on the current run loop. */
- (BOOL)startNotifier;
- (void)stopNotifier;

- (NetworkStatus)currentReachabilityStatus;

@end


