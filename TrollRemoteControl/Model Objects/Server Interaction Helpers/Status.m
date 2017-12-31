//
//  Status.m
//  RemoteServerMonitor, TrollRemoteControl
//
//  Created by Pete Maiser on 1/7/16.
//  Copyright © 2016 Pete Maiser. All rights reserved.
//

#import "Status.h"
#import "RemoteServer.h"

@interface Status ()
@property (nonatomic, copy) NSString *statusCommandValue;
@end

@implementation Status

- (instancetype)initWithVariable:(NSString *)variable
                    commandValue:(NSString *)commandValue
{
    self = [super init];
    if (self) {
        self.variable = variable;
        self.statusCommandValue = commandValue;
        self.value = @"";
        self.state = RemoteStatusStateNone;
    }
    return self;
}

- (void)sendStatusCommandToServer:(RemoteServer *)server
                       withPrefix:(NSString *)prefix
{
    NSString *commandString = [NSString stringWithFormat:@"%@%@%@"
                               ,prefix
                               ,self.variable
                               ,self.statusCommandValue];
    [server sendString:commandString];
}

- (instancetype)copyWithZone:(NSZone *)zone
{
    Status *copy = [[Status alloc] init];
    
    copy.variable = [self.variable copy];
    copy.statusCommandValue = [self.statusCommandValue copy];
    copy.value = [self.value copy];
    copy.state = self.state;
    
    return copy;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.variable forKey:@"variable"];
    [aCoder encodeObject:self.statusCommandValue forKey:@"statusCommandValue"];
    [aCoder encodeObject:self.value forKey:@"value"];
    [aCoder encodeInteger:self.state forKey:@"state"];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        _variable = [aDecoder decodeObjectForKey:@"variable"];
        _statusCommandValue = [aDecoder decodeObjectForKey:@"statusCommandValue"];
        _value = [aDecoder decodeObjectForKey:@"value"];
        _state = [aDecoder decodeIntegerForKey:@"state"];
    }
    return self;
}

@end
