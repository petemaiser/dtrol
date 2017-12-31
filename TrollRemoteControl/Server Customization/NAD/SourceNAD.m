//
//  SourceNAD.m
//  DTrol
//
//  Created by Pete Maiser on 12/9/17.
//  Copyright © 2017 Pete Maiser. All rights reserved.
//

#import "SourceNAD.h"

@implementation SourceNAD

- (instancetype)copyWithZone:(NSZone *)zone
{
    SourceNAD *copy = [super copyWithZone:zone];
    
    copy.prefix   = [self.prefix copy];
    
    return copy;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    
    [aCoder encodeObject:self.prefix forKey:@"prefix"];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        _prefix   = [aDecoder decodeObjectForKey:@"prefix"];
    }
    return self;
}


@end
