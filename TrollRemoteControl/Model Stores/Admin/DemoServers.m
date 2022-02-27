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
            @"serverIP": @"192.168.30.50",
            @"customIfString": @"Main.Volume=-20",
            @"customThenString": @"Main.Volume=0",
            @"zone1.nameLong": @"Main",
            @"zone2.nameLong": @"TNR GR & FR",
            @"zone3.nameLong": @"TNR RackDown",
            @"zone4.nameLong": @"TNR RackUp",
            @"tunerOverride.IP": @"",
            @"tunerOverride.zone.nameLong": @"",
            @"zone1.isHidden": [NSNumber numberWithBool:YES],
            @"zone2.isHidden": [NSNumber numberWithBool:YES],
            @"zone3.isHidden": [NSNumber numberWithBool:YES],
            @"zone4.isHidden": [NSNumber numberWithBool:YES],
        };
        
        NSDictionary *demoServer2 = @{
            // RU
            @"serverIP": @"192.168.30.51",
            @"customIfString": @"Main.Volume=-20",
            @"customThenString": @"Main.Volume=0",
            @"zone1.nameLong": @"Airplay DAC",
            @"zone2.nameLong": @"Master Bath",
            @"zone3.nameLong": @"Laundry Room",
            @"zone4.nameLong": @"Deck",
            @"tunerOverride.IP": @"192.168.30.50",
            @"tunerOverride.zone.nameLong": @"TNR RackUp",
            @"zone1.isHidden": [NSNumber numberWithBool:YES],
            @"zone2.isHidden": [NSNumber numberWithBool:NO],
            @"zone3.isHidden": [NSNumber numberWithBool:NO],
            @"zone4.isHidden": [NSNumber numberWithBool:NO],
        };

        NSDictionary *demoServer3 = @{
            // GR
            @"serverIP": @"192.168.30.52",
            @"customIfString": @"",
            @"customThenString": @"",
            @"zone1.nameLong": @"Main",
            @"zone2.nameLong": @"Zone 2",
            @"zone3.nameLong": @"GR Sitting",
            @"zone4.nameLong": @"GR Kitchen",
            @"tunerOverride.IP": @"192.168.30.50",
            @"tunerOverride.zone.nameLong": @"TNR GR & FR",
            @"zone1.isHidden": [NSNumber numberWithBool:YES],
            @"zone2.isHidden": [NSNumber numberWithBool:YES],
            @"zone3.isHidden": [NSNumber numberWithBool:NO],
            @"zone4.isHidden": [NSNumber numberWithBool:NO],
        };
        
        NSDictionary *demoServer4 = @{
            // RD
            @"serverIP": @"192.168.30.53",
            @"customIfString": @"Main.Volume=-20",
            @"customThenString": @"Main.Volume=0",
            @"zone1.nameLong": @"Alexa DAC",
            @"zone2.nameLong": @"Music Room",
            @"zone3.nameLong": @"Screen Porch",
            @"zone4.nameLong": @"Exercise Room",
            @"tunerOverride.IP": @"192.168.30.50",
            @"tunerOverride.zone.nameLong": @"TNR RackDown",
            @"zone1.isHidden": [NSNumber numberWithBool:YES],
            @"zone2.isHidden": [NSNumber numberWithBool:NO],
            @"zone3.isHidden": [NSNumber numberWithBool:NO],
            @"zone4.isHidden": [NSNumber numberWithBool:NO],
        };
        
        NSDictionary *demoServer5 = @{
            // RD
            @"serverIP": @"192.168.30.54",
            @"customIfString": @"",
            @"customThenString": @"",
            @"zone1.nameLong": @"Family Room",
            @"zone2.nameLong": @"Zone 2",
            @"zone3.nameLong": @"Zone 3",
            @"zone4.nameLong": @"",
            @"tunerOverride.IP": @"192.168.30.50",
            @"tunerOverride.zone.nameLong": @"TNR GR & FR",
            @"zone1.isHidden": [NSNumber numberWithBool:NO],
            @"zone2.isHidden": [NSNumber numberWithBool:YES],
            @"zone3.isHidden": [NSNumber numberWithBool:YES],
            @"zone4.isHidden": [NSNumber numberWithBool:YES],
        };
        
        self.privateList = [[NSMutableArray alloc] initWithObjects:demoServer1, demoServer2, demoServer3, demoServer4, demoServer5, nil];
        
    }
    return self;
}

- (NSArray *)list
{
    //Override the getter of the array to return a copy of private items
    return [self.privateList copy];
}


@end
