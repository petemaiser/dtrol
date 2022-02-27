//
//  TunerStation.m
//  DTrol
//
//  Created by Pete Maiser on 11/21/17.
//  Copyright © 2017 Pete Maiser. All rights reserved.
//

#import "TunerStation.h"
@class RemoteServer;

@implementation TunerStation

- (instancetype)init
{
    self = [super init];
    
    // Set default values
    if (self ) {
        self.frequencyText = @"";
    }
    return self;
}

- (void)sendStationCommandToServer:(RemoteServer *)server
{
    // Subclasses need to implement this
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.frequencyText forKey:@"frequencyText"];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        _frequencyText = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"frequencyText"];
    }
    return self;
}

+ (BOOL)supportsSecureCoding
{
    return YES;
}

@end
