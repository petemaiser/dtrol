//
//  DemoServers.m
//  DTrol
//
//  Created by Pete Maiser on 2/15/22.
//  Copyright © 2022 Pete Maiser. All rights reserved.
//

#import "DemoServers.h"

@interface DemoServers ()
@property (nonatomic) NSMutableArray *privateList;
@end

@implementation DemoServers

- (instancetype)init
{
    // This is the real initializer
    self = [super init];
    if (self) {
        
        NSDictionary *demoServer1 = @{
            // TNR
            @"serverIP": @"192.168.0.90",
            @"customIfString": @"Main.Volume=-20",
            @"customThenString": @"Main.Volume=0",
            @"zone1.nameLong": @"Main Zone",
            @"zone2.nameLong": @"Bluesound Tuner",
            @"zone3.nameLong": @"Zone 3",
            @"zone4.nameLong": @"Zone 4",
            @"tunerOverride.IP": @"",
            @"tunerOverride.zone.nameLong": @"",
            @"zone1.isHidden": [NSNumber numberWithBool:YES],
            @"zone2.isHidden": [NSNumber numberWithBool:NO],
            @"zone3.isHidden": [NSNumber numberWithBool:YES],
            @"zone4.isHidden": [NSNumber numberWithBool:YES],
        };
        
        self.privateList = [[NSMutableArray alloc] initWithObjects:demoServer1, nil];
        
    }
    return self;
}

- (NSArray *)list
{
    //Override the getter of the array to return a copy of private items
    return [self.privateList copy];
}


@end
