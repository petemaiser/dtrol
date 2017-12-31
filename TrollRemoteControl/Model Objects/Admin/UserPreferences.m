//
//  UserPreferences.m
//  DTrol
//
//  Created by Pete Maiser on 1/4/17.
//  Copyright © 2017 Pete Maiser. All rights reserved.
//

#import "UserPreferences.h"

@implementation UserPreferences

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.showZoneSetupButtons = YES;
        self.enableAutoPowerOnTuner = YES;
        self.enableAutoPowerOnAirplay = YES;
    }
    return self;
}

- (NSTimeInterval)timeout
{
    return 10;
}

- (void) encodeWithCoder:( NSCoder *) aCoder
{
    [aCoder encodeBool:self.showZoneSetupButtons forKey:@"showZoneSetupButtons"];
    [aCoder encodeBool:self.enableAutoPowerOnTuner forKey:@"enableAutoPowerOnTuner"];
    [aCoder encodeBool:self.enableAutoPowerOnAirplay forKey:@"enableAutoPowerOnAirplay"];
}

- (instancetype) initWithCoder:( NSCoder *) aDecoder
{
    self = [super init];
    if (self) {
        _showZoneSetupButtons = [aDecoder decodeBoolForKey:@"showZoneSetupButtons"];
        _enableAutoPowerOnTuner = [aDecoder decodeBoolForKey:@"enableAutoPowerOnTuner"];
        _enableAutoPowerOnAirplay = [aDecoder decodeBoolForKey:@"enableAutoPowerOnTuner"];
    }
    return self;
}

@end
