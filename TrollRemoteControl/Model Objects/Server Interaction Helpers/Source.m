//
//  Source.m
//  RemoteServerMonitor, TrollRemoteControl
//
//  Created by Pete Maiser on 1/2/16.
//  Copyright © 2016 Pete Maiser. All rights reserved.
//

#import "Source.h"
#import "Command.h"
@class RemoteServer;

@interface Source ()
@property (nonatomic, copy) NSString *variable;
@property (nonatomic) Command *sourceCommand;
@end

@implementation Source

- (instancetype)initWithName:(NSString *)name
                    variable:(NSString *)variable
                       value:(NSString *)value
               sourceCommand:(Command *)command
                     enabled:(NSString *)enabled
{
    self = [super init];
    if (self) {
        self.name = name;
        self.variable = variable;
        self.value = value;
        self.sourceCommand = [command copy];
        self.enabled = enabled;
    }
    return self;
}

- (void)sendSourceCommandToServer:(RemoteServer *)server
                       withPrefix:(NSString *)prefix
{
    [self.sourceCommand sendCommandToServer:server withPrefix:prefix];
}

- (instancetype)copyWithZone:(NSZone *)zone
{
    Source *copy = [[Source alloc] init];
    copy.name     = [self.name copy];
    copy.variable = [self.variable copy];
    copy.value    = [self.value copy];
    copy.sourceCommand  = [self.sourceCommand copy];
    copy.enabled  = [self.enabled copy];
    
    return copy;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.name forKey:@"name"];
    [aCoder encodeObject:self.variable forKey:@"variable"];
    [aCoder encodeObject:self.value forKey:@"value"];
    [aCoder encodeObject:self.sourceCommand forKey:@"sourceCommand"];
    [aCoder encodeObject:self.enabled forKey:@"enabled"];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        _name     = [aDecoder decodeObjectForKey:@"name"];
        _variable = [aDecoder decodeObjectForKey:@"variable"];
        _value    =    [aDecoder decodeObjectForKey:@"value"];
        _sourceCommand  =  [aDecoder decodeObjectForKey:@"sourceCommand"];
        _enabled  =  [aDecoder decodeObjectForKey:@"enabled"];
    }
    return self;
}

@end
