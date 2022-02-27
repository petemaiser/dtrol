//
//  Hyperlink.h
//  RemoteServerMonitor, TrollRemoteControl
//
//  Created by Pete Maiser on 1/2/16.
//  Copyright © 2016 Pete Maiser. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Hyperlink : NSObject <NSCopying, NSSecureCoding>

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *address;

- (instancetype)initWithName:(NSString *)name
                     address:(NSString *)address;

@end
