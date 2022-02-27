//
//  Hyperlink.m
//  RemoteServerMonitor, TrollRemoteControl
//
//  Created by Pete Maiser on 1/2/16.
//  Copyright © 2016 Pete Maiser. All rights reserved.
//

#import "Hyperlink.h"

@implementation Hyperlink

- (instancetype)initWithName:(NSString *)name
                     address:(NSString *)address
{
    self = [super init];
    if (self) {
        self.name = name;
        self.address = address;
    }
    return self;
    
}

- (instancetype)copyWithZone:(NSZone *)zone
{
    Hyperlink *copy = [[Hyperlink alloc] init];
 
    copy.name = [self.name copy];
    copy.address = [self.address copy];
    
    return copy;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.name forKey:@"name"];
    [aCoder encodeObject:self.address forKey:@"address"];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        _name = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"name"];
        _address = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"address"];
    }
    return self;
}

+ (BOOL)supportsSecureCoding
{
    return YES;
}

@end
