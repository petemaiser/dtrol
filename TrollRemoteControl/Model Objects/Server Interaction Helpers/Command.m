//
//  Command.m
//  RemoteServerMonitor, TrollRemoteControl
//
//  Created by Pete Maiser on 1/2/16.
//  Copyright © 2016 Pete Maiser. All rights reserved.
//

#import "Command.h"
#import "RemoteServer.h"

@interface Command ()

// The prefix the processor may expect between the root command and a parameter
@property (nonatomic, copy) NSString *parameterPrefix;

// Version number to be saved in archive so that future model changes can be
// made backwards-compatible with old versions.
@property (nonatomic) NSUInteger modelObjectVersion;

@end;

@implementation Command

- (instancetype)initWithVariable:(NSString *)variable
              parameterPrefix:(NSString *)parameterPrefix
                    parameter:(NSString *)parameter
{
    self = [super init];
    if (self) {
        self.variable = variable;
        self.parameterPrefix = parameterPrefix;
        self.parameter = parameter;
        self.modelObjectVersion = 1;
    }
    return self;
}

- (void)sendCommandToServer:(RemoteServer *)server
                 withPrefix:(NSString *)prefix
{    
    NSString *commandString = [NSString stringWithFormat:@"%@%@%@%@"
                               ,prefix
                               ,self.variable
                               ,self.parameterPrefix
                               ,self.parameter];
    [server sendString:commandString];
}

- (instancetype)copyWithZone:(NSZone *)zone
{
    Command *copy = [[[self class] allocWithZone:zone] init];
    
    copy.variable = [self.variable copy];
    copy.parameterPrefix = [self.parameterPrefix copy];
    copy.parameter = [self.parameter copy];
    copy.modelObjectVersion  = self.modelObjectVersion;
    
    return copy;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.variable forKey:@"variable"];
    [aCoder encodeObject:self.parameterPrefix forKey:@"parameterPrefix"];
    [aCoder encodeObject:self.parameter forKey:@"parameter"];
    [aCoder encodeInteger:self.modelObjectVersion forKey:@"modelObjectVersion"];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {

        _variable = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"variable"];
        _modelObjectVersion = [aDecoder decodeIntegerForKey:@"modelObjectVersion"];
        
        if (_modelObjectVersion >= 1) {
            _parameterPrefix = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"parameterPrefix"];
            _parameter = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"parameter"];
        } else {
            _parameterPrefix = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"commandValuePrefix"];
            _parameter = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"commandValue"];
            _modelObjectVersion = 1;
        }

    }
    return self;
}

+ (BOOL)supportsSecureCoding
{
    return YES;
}

@end
