//
//  Log.h
//  GameCalc, TrollRemoteControl
//
//  Created by Pete Maiser on 3/25/16.
//  Copyright © 2016 Pete Maiser. All rights reserved.
//

#import <Foundation/Foundation.h>
@class LogItem;

@interface Log : NSObject

@property (nonatomic, readonly, copy) NSArray *logItems;

+ (instancetype)sharedLog;

- (void)addItem:(LogItem *)logItem;
- (void)addDivider;

- (BOOL)saveLog;

enum
{
    maxItems = 1000
};

@end
