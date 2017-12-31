//
//  RemoteComponent.m
//  TrollRemoteControl
//
//  Created by Pete Maiser on 7/31/16.
//  Copyright © 2016 Pete Maiser. All rights reserved.
//

#import "RemoteComponent.h"
#import "RemoteServer.h"
#import "RemoteServerList.h"
#import "Status.h"
#import "Log.h"
#import "LogItem.h"

@implementation RemoteComponent

- (instancetype)init
{
    self = [super init];
    
    // Set default values
    if (self) {
        _server = nil;
        _serverUUID = nil;
        self.logFile = @"";
        self.prefixValue = nil;
        self.statusSet = nil;
        self.mustRequestStatus = NO;
        self.modelObjectVersion = 1;
    }
    
    return self;
}

- (void)setServerAsUUID:(NSUUID *)serverUUID
{
    _serverUUID = serverUUID;
    _server = [[RemoteServerList sharedList] getServerWithUUID:serverUUID];
    
    // Setup a request for status when streams are opened
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(sendRequestForStatus)
                                                 name:StreamsReadyNotificationString
                                               object:_server];
}

- (void)sendRequestForStatus
{
    for (Status *status in self.statusSet) {
        [status sendStatusCommandToServer:self.server withPrefix:self.prefixValue];
    }
}

- (void)handleString:(NSString *)string
          fromServer:(RemoteServer *)server
{
    // Subclasses need to implement this
}

- (void)logString:(NSString *)str
{
    
    if (!self.logFile) {
    
        NSLog(@"%@", str);
    
    } else if ([self.logFile isEqualToString:@""]) {
        
        Log *sharedLog = [Log sharedLog];
        if (sharedLog) {
            LogItem *logTextLine1 = [LogItem logItemWithText:str];
            [sharedLog addItem:logTextLine1];
        }
        
    } else {
        
        NSString *programName = [NSString stringWithUTF8String:getprogname()];
        
        NSDate *date = [NSDate date];
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
        
        NSString *formattedString = [NSString stringWithFormat:@"%@ %@: %@\n", programName ,[dateFormatter stringFromDate:date], str];
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if(![fileManager fileExistsAtPath:self.logFile])
        {
            [formattedString writeToFile:self.logFile
                              atomically:YES
                                encoding:NSUTF8StringEncoding
                                   error:nil];
        }
        else
        {
            NSFileHandle *myHandle = [NSFileHandle fileHandleForWritingAtPath:self.logFile];
            [myHandle seekToEndOfFile];
            [myHandle writeData:[formattedString dataUsingEncoding:NSUTF8StringEncoding]];
        }
        
    }
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.serverUUID forKey:@"serverUUID"];
    [aCoder encodeObject:self.logFile forKey:@"logFile"];
    [aCoder encodeObject:self.nameShort forKey:@"nameShort"];
    [aCoder encodeObject:self.nameLong forKey:@"nameLong"];
    [aCoder encodeObject:self.prefixValue forKey:@"prefixValue"];
    [aCoder encodeObject:self.statusSet forKey:@"statusSet"];
    [aCoder encodeBool:self.mustRequestStatus forKey:@"mustRequestStatus"];
    [aCoder encodeInteger:self.modelObjectVersion forKey:@"modelObjectVersion"];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [self init];
    if (self) {
        [self setServerAsUUID:[aDecoder decodeObjectForKey:@"serverUUID"]];
        _logFile = [aDecoder decodeObjectForKey:@"logFile"];
        _nameShort = [aDecoder decodeObjectForKey:@"nameShort"];
        _nameLong = [aDecoder decodeObjectForKey:@"nameLong"];
        _prefixValue = [aDecoder decodeObjectForKey:@"prefixValue"];
        _statusSet = [aDecoder decodeObjectForKey:@"statusSet"];
        _mustRequestStatus = [aDecoder decodeBoolForKey:@"mustRequestStatus"];
        _modelObjectVersion = [aDecoder decodeIntegerForKey:@"modelObjectVersion"];
    }
    return self;
}

@end
