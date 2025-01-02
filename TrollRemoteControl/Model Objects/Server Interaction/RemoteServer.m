//
//  RemoteServer.m
//  RemoteServerMonitor, TrollRemoteControl
//
//  Created by Pete Maiser on 1/2/16.
//  Copyright © 2016 Pete Maiser. All rights reserved.
//

#import "RemoteServer.h"
#import "Command.h"
#import "Source.h"
#import "Reachability.h"
#import "RemoteComponent.h"
#import "RemoteTunerList.h"
#import "RemoteZoneList.h"
#import "Log.h"
#import "LogItem.h"

@interface RemoteServer ()

@property (nonatomic) NSMutableArray *privateSourceList;

@property (nonatomic) NSMutableData *data;
@property (nonatomic) NSInputStream *iStream;
@property (nonatomic) NSOutputStream *oStream;

@property (nonatomic) NSMutableArray *blocksForIncomingStream;

@property (nonatomic) NSString *stringFragment;

@end

@implementation RemoteServer


#pragma mark - Server Initialization

+ (RemoteServer *)createServerWithIP:(NSString *)serverIP
                                port:(uint)serverPort
               lineTerminationString:(NSString *)termString
{
    RemoteServer *server;
    server = [[self alloc] initServerWithIP:serverIP port:serverPort lineTerminationString:termString];
    return server;
}

- (instancetype)init
{
    self = [super init];
    
    NSLog(@"WARNING init called, but generally for this class initServerWithIP should be used as designated initializer.  Execution with continue.");

    if (self) {
        _dateCreated = [[NSDate alloc] init];
        _isConnected = NO;
        _serverUUID = [[NSUUID alloc] init];
        _privateSourceList = [[NSMutableArray alloc] init];
        _stringFragment  = @"";
    }
    return self;
}

- (instancetype)initServerWithIP:(NSString *)serverIP
                            port:(uint)serverPort
           lineTerminationString:(NSString *)termString
{
    self = [super init];
    if (self) {

        _dateCreated = [[NSDate alloc] init];
        _isConnected = NO;
        _serverUUID = [[NSUUID alloc] init];
        _privateSourceList = [[NSMutableArray alloc] init];
        
        self.address = [[NSString alloc] initWithFormat:@"%@:%u", serverIP, serverPort];
        self.IP = serverIP;
        self.port = serverPort;
        self.lineTerminationString = termString;
        self.stringFragment = @"";
        
        // Set defaults
        self.treatSpaceAsLineTermination = YES;
        self.logFile = @"";
        self.nameShort = @"";
        self.model = @"";
        self.autoOnSourceValue = @"";
        
        self.customIfString = @"";
        self.customThenString = @"";
    
        // Setup handling for a reachability change
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(reachabilityChanged:)
                                                     name:kReachabilityChangedNotification
                                                   object:nil];
    }
    return self;
}

- (void)openStreams
{
    if (self) {

        CFReadStreamRef readStream = NULL;
        CFWriteStreamRef writeStream = NULL;
        
        CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault,
                                           (__bridge CFStringRef)(self.IP),
                                           self.port,
                                           &readStream,
                                           &writeStream);
        
        if (readStream && writeStream) {
            CFReadStreamSetProperty(readStream,
                                    kCFStreamPropertyShouldCloseNativeSocket,
                                    kCFBooleanTrue);
            CFWriteStreamSetProperty(writeStream,
                                     kCFStreamPropertyShouldCloseNativeSocket,
                                     kCFBooleanTrue);
            
            self.iStream = (__bridge NSInputStream *)readStream;
            [self.iStream setDelegate:self];
            [self.iStream scheduleInRunLoop:[NSRunLoop currentRunLoop]
                                    forMode:NSDefaultRunLoopMode];
            [self.iStream open];
            
            self.oStream = (__bridge NSOutputStream *)writeStream;
            [self.oStream setDelegate:self];
            [self.oStream scheduleInRunLoop:[NSRunLoop currentRunLoop]
                                    forMode:NSDefaultRunLoopMode];
            [self.oStream open];
        }
    }
}


#pragma mark - Callback setup and management

- (void)addBlockForIncomingStrings:(void (^)(NSString *))callbackBlock
{
    if (!self.blocksForIncomingStream) {
        self.blocksForIncomingStream = [[NSMutableArray alloc] init];
    }
    [self.blocksForIncomingStream addObject:callbackBlock];
}

- (void)removeBlockForIncomingStrings:(void (^)(NSString *))callbackBlock
{
    if (self.blocksForIncomingStream) {
        [self.blocksForIncomingStream removeObject:callbackBlock];
    }
}


#pragma mark - Server Interaction

- (void)stream:(NSStream *)stream
   handleEvent:(NSStreamEvent)eventCode
{
    // NSStreamDelegate
    
    NSString *streamID = @"";
    
    if (stream == self.iStream) {
        streamID = @"READ ";
    } else if (stream == self.oStream) {
        streamID = @"WRITE ";
    }
    
    NSNotification *eventNotification = nil;
    NSPostingStyle eventNotificationPostingStye = NSPostASAP;
    
    switch(eventCode) {
            
        case NSStreamEventEndEncountered:{
            
            [stream close];
            [stream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
            
            NSString * status = [NSString stringWithFormat:@"%@CONNECTION CLOSED (%@)", streamID, self.nameShort];
            [self logString:status];
            
            if ( (self.isConnected == NO) &&
                 ([self streamsClosed]) )
            {
                eventNotification = [NSNotification notificationWithName:StreamClosedNotificationString object:self];
            }
            self.isConnected = NO;
            
        } break;
            
        case NSStreamEventErrorOccurred:{
            
            NSString * status = [NSString stringWithFormat:@"ERROR OCCURRED IN %@STREAM (%@)", streamID, self.nameShort];
            [self logString:status];
            
            eventNotification = [NSNotification notificationWithName:StreamErrorNotificationString object:self];
            eventNotificationPostingStye = NSPostWhenIdle;
            
        } break;
            
        case NSStreamEventHasBytesAvailable:{
            
            if (self.data == nil) {
                self.data = [[NSMutableData alloc] init];
            }
            
            uint8_t buf[1024];
            NSInteger len = 0;
            len = [(NSInputStream *)stream read:buf maxLength:1024];
            
            if(len) {
                NSString * status = [NSString stringWithFormat:@"RECEIVED (%@):  %ld bytes", self.nameShort, (long)len];
                [self logString:status];
                [self.data appendBytes:(const void *)buf length:len];
            } else {
                NSString * status = [NSString stringWithFormat:@"NO DATA IN %@STREAM (%@)", streamID, self.nameShort];
                [self logString:status];
            }
            
            NSString *receiveString = [[NSString alloc] initWithData:self.data encoding:NSUTF8StringEncoding];
            
            NSArray *receiveStrings = [receiveString componentsSeparatedByString:self.lineTerminationString]; // Divide the string by any terminators
            NSInteger stringCount = [receiveStrings count];
            
            BOOL tunerCount = [[[RemoteTunerList sharedList] tuners] count];
            BOOL zoneCount = [[[RemoteZoneList sharedList] zones] count];
            
            for (NSInteger i = 0; i < (stringCount - 1); i++) {
                
                NSString *responseString = receiveStrings[i];
                
                if (self.blocksForIncomingStream) {
                    for (void (^callbackBlock)(NSString *) in self.blocksForIncomingStream) {
                        callbackBlock(responseString);
                    }
                }
            
                if (tunerCount > 0) {
                    [[RemoteTunerList sharedList] handleString:responseString
                                                   fromServer:self];
                }
                
                if (zoneCount > 0) {
                    [[RemoteZoneList sharedList] handleString:responseString
                                                   fromServer:self];
                }
                
                
                if ([responseString isEqualToString:self.customIfString]) {
                    [self sendString:self.customThenString];
                }
                
            }
            
            // The for loop above leaves out the last string.  This is because componentsSeparatedByString will produce an empty string
            // if the string ends with the separator - which is the expected behavior here (the server should be separating every command
            // by the lineTerminationString).  If the last string is NOT empty...that means that for whatever reason* a response from the
            // server may have been cut-off.  That last non-empty string may be a fragment of a complete string, and the first string in the next
            // set of received data may be the rest of it.  So let's save it.  We will process it, and we will will do one round of the
            // next first string in the next event by prepending this bit of string on to the first string in the next event.
            
            // * Why would this happen?  The buffer may be full (make the buffer bigger you say? well at some point it has to have limit);
            // I have also seen cases where strings seem to get cut-off, probably a timing issue of some fashion in NSStream.
            // Might as well just handle the case as it does seem to happen and handling it in this way does little if any harm.

            ///START  string fragment processing
            if (stringCount > 0) {
            
                // Fragment from the previous event
                if (![self.stringFragment isEqualToString:@""]) {
                
                    NSString *mendedString = [NSString stringWithFormat:@"%@%@", self.stringFragment, receiveStrings[0]];
 
                    if (self.blocksForIncomingStream) {
                        for (void (^callbackBlock)(NSString *) in self.blocksForIncomingStream) {
                            callbackBlock(mendedString);
                        }
                    }
                    if (tunerCount > 0) {
                        [[RemoteTunerList sharedList] handleString:mendedString
                                                        fromServer:self];
                    }
                    if (zoneCount > 0) {
                        [[RemoteZoneList sharedList] handleString:mendedString
                                                       fromServer:self];
                    }
                    if ([mendedString isEqualToString:self.customIfString]) {
                        [self sendString:self.customThenString];
                    }
        
                }
                
                // Fragment from this event
                self.stringFragment = receiveStrings[stringCount -1];
                if (![self.stringFragment isEqualToString:@""]) {
                    if (self.blocksForIncomingStream) {
                        for (void (^callbackBlock)(NSString *) in self.blocksForIncomingStream) {
                            callbackBlock(self.stringFragment);
                        }
                    }
                    if (tunerCount > 0) {
                        [[RemoteTunerList sharedList] handleString:self.stringFragment
                                                        fromServer:self];
                    }
                    if (zoneCount > 0) {
                        [[RemoteZoneList sharedList] handleString:self.stringFragment
                                                       fromServer:self];
                    }
                }
            
            }   // END string fragment processing
            
            if ((!self.blocksForIncomingStream) &&
                (tunerCount <= 0) &&
                (zoneCount <= 0)) {  // No callbacks have been set for received data, so write any received data to log
                NSString * status = [NSString stringWithFormat:@"NOT PROCESSED (%@):  \"%@\"", self.nameShort, receiveString];
                [self logString:status];
            }
            
            eventNotification = [NSNotification notificationWithName:StreamNewDataNotificationString object:self];
            
            self.data = nil;
            
        } break;
            
        case NSStreamEventOpenCompleted:{
            
            NSString * status = [NSString stringWithFormat:@"%@CONNECTION OPEN (%@)", streamID, self.nameShort];
            [self logString:status];
            
            if ( !self.isConnected && [self streamsReady]) {
                self.isConnected = YES;
                eventNotification = [NSNotification notificationWithName:StreamsReadyNotificationString object:self];
            }

        } break;
            
        default:
            break;
    }
    
    if (eventNotification) {
        [[NSNotificationQueue defaultQueue] enqueueNotification:eventNotification
                                                   postingStyle:eventNotificationPostingStye
                                                   coalesceMask:NSNotificationCoalescingOnName|NSNotificationCoalescingOnSender
                                                       forModes:nil];
    }
}

- (void)sendString:(NSString *)str
{
    if ([str isEqualToString:@""]) {
        return;
    }
    
    NSString *sendString;
    
    if (self.treatSpaceAsLineTermination) {
        sendString = [str stringByReplacingOccurrencesOfString:@" "
                                                     withString:self.lineTerminationString];
    } else {
        sendString = str;
    }
    
    if(![sendString hasSuffix:self.lineTerminationString]) {
        sendString = [NSString stringWithFormat:@"%@%@", str, self.lineTerminationString];
    }
    
    const uint8_t *sendBuffer = (uint8_t *)[sendString cStringUsingEncoding:NSASCIIStringEncoding];
    [self.oStream write:sendBuffer maxLength:strlen((char*)sendBuffer)];
    
    NSString * status = [NSString stringWithFormat:@"SENT (%@): %@", self.nameShort, str];
    [self logString:status];
}

- (void)closeStreams
{
    if (![self streamsClosed]) {
    
        NSString *status = nil;
        [self.oStream close];
        status = [NSString stringWithFormat:@"CLOSING WRITE CONNECTION (%@)", self.nameShort];
        [self logString:status];
        
        status = nil;
        [self.iStream close];
        status = [NSString stringWithFormat:@"CLOSING READ CONNECTION (%@)", self.nameShort];
        [self logString:status];
        
        self.isConnected = NO;
        
        NSNotification *eventNotification = [NSNotification notificationWithName:StreamClosedNotificationString object:self];
        if (eventNotification) {
            [[NSNotificationQueue defaultQueue] enqueueNotification:eventNotification
                                                       postingStyle:NSPostASAP
                                                       coalesceMask:NSNotificationCoalescingOnName
                                                           forModes:nil];
        }
    }
}


#pragma mark - Admin

- (NSArray *)sourceList
{
    // Override the getter of the array to return a copy of private items - only those that are enabled
    NSMutableArray *enabledSourceList = [[NSMutableArray alloc] init];
    
    for (NSInteger i=0; i < [self.privateSourceList count]; i++) {
        Source *s = self.privateSourceList[i];
        if (s.enabled.boolValue) {
            [enabledSourceList addObject:s];
        }
    }
    
    return enabledSourceList;
}

- (NSString *)nameLong
{
    // Override the getter to reply with a manufactured Long Name
    return [NSString stringWithFormat:@"%@ %@ at %@", self.nameShort, self.model, self.address];
}

- (NSArray *)sourceListAll
{
    // Override the getter of the array to return a copy of private items
    return [self.privateSourceList copy];
}

- (void)addSource:(Source *)source
{
    if (source) {
        [self.privateSourceList addObject:source];
    }
}

- (BOOL)streamsReady
{
    NSStreamStatus readStreamStatus = [self.iStream streamStatus];
    NSStreamStatus writeStreamStatus = [self.oStream streamStatus];
    
    if ( ( (readStreamStatus == NSStreamStatusOpen) ||
           (readStreamStatus == NSStreamStatusReading) ||
           (readStreamStatus == NSStreamStatusWriting) ) &&
         (
           (writeStreamStatus == NSStreamStatusOpen) ||
           (writeStreamStatus == NSStreamStatusReading) ||
           (writeStreamStatus == NSStreamStatusWriting) )  )
    {
        return YES;
    }
    
    return NO;
}

- (BOOL)streamsNeedOpen
{
    NSStreamStatus readStreamStatus = [self.iStream streamStatus];
    NSStreamStatus writeStreamStatus = [self.oStream streamStatus];
    
    if ( (readStreamStatus == NSStreamStatusNotOpen) ||
         (readStreamStatus == NSStreamStatusClosed) ||
         (readStreamStatus == NSStreamStatusError) ||
         (writeStreamStatus == NSStreamStatusNotOpen) ||
         (writeStreamStatus == NSStreamStatusClosed) ||
         (writeStreamStatus == NSStreamStatusError) )
    {
        return YES;
    }
    
    return NO;
}

- (BOOL)streamsClosed
{
    NSStreamStatus readStreamStatus = [self.iStream streamStatus];
    NSStreamStatus writeStreamStatus = [self.oStream streamStatus];
    
    if ( (readStreamStatus == NSStreamStatusClosed) &&
         (writeStreamStatus == NSStreamStatusClosed) )
    {
        return YES;
    }
    
    return NO;
}


- (void)reachabilityChanged:(NSNotification *)note
{
    Reachability* reachability = [note object];
    NSParameterAssert([reachability isKindOfClass:[Reachability class]]);
    
    if ([reachability currentReachabilityStatus] == ReachableViaWiFi) {
             
        if ([self streamsNeedOpen]) {
             [self openStreams];
         }
        
    } else {
        [self closeStreams];
    }
}

- (void)attemptRecoveryFromStreamError
{
    Reachability *reachability = [Reachability sharedReachability];
    if ([reachability currentReachabilityStatus] == ReachableViaWiFi) {
        [self closeStreams];
        [self openStreams];
    }
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
        
        NSString *formattedString = [NSString stringWithFormat:@"%@ %@: %@ (Server %@)\n", programName ,[dateFormatter stringFromDate:date], str, self.address];
        
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
    [aCoder encodeObject:self.dateCreated forKey:@"dateCreated"];
    
    [aCoder encodeObject:self.logFile forKey:@"logFile"];

    [aCoder encodeObject:self.model forKey:@"model"];
    [aCoder encodeObject:self.nameShort forKey:@"nameShort"];
    [aCoder encodeObject:self.address forKey:@"address"];
    
    [aCoder encodeObject:self.privateSourceList forKey:@"privateSourceList"];
    [aCoder encodeObject:self.autoOnSourceValue forKey:@"autoOnSourceValue"];
    [aCoder encodeObject:self.tunerSourceValue forKey:@"tunerSourceValue"];
    [aCoder encodeObject:self.mainZoneSourceValue forKey:@"mainZoneSourceValue"];
    
    [aCoder encodeObject:self.IP forKey:@"IP"];
    [aCoder encodeInt:self.port forKey:@"port"];
    [aCoder encodeObject:self.lineTerminationString forKey:@"lineTerminationString"];
    [aCoder encodeBool:self.treatSpaceAsLineTermination forKey:@"treatSpaceAsLineTermination"];
    
    [aCoder encodeObject:self.customIfString forKey:@"customIfString"];
    [aCoder encodeObject:self.customThenString forKey:@"customThenString"];
    
    // clear out the notification, set it up again when a new Server entry is created later with initWithCoder
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                 name:kReachabilityChangedNotification
                                               object:self];
    
    
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        
        _serverUUID = [aDecoder decodeObjectOfClass:[NSUUID class] forKey:@"serverUUID"];
        _dateCreated = [aDecoder decodeObjectOfClass:[NSDate class] forKey:@"dateCreated"];
        
        _isConnected = NO;
        _stringFragment  = @"";
        
        _logFile = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"logFile"];

        _model = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"model"];
        _nameShort = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"nameShort"];
        _address = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"address"];

        NSSet *classes = [NSSet setWithObjects:[NSMutableArray class]
                                                ,[Command class]
                                                ,[Source class]
                                                ,[NSString class]
                                                ,nil];
        _privateSourceList = [aDecoder decodeObjectOfClasses:classes forKey:@"privateSourceList"];
        _autoOnSourceValue = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"autoOnSourceValue"];
        if (_autoOnSourceValue == nil) {
            // backwards-compatibility
            _autoOnSourceValue = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"airplaySourceValue"];
        }
        _tunerSourceValue = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"tunerSourceValue"];
        _mainZoneSourceValue = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"mainZoneSourceValue"];
        
        _IP = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"IP"];
        _port = [aDecoder decodeIntForKey:@"port"];
        _lineTerminationString = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"lineTerminationString"];
        _treatSpaceAsLineTermination = [aDecoder decodeBoolForKey:@"treatSpaceAsLineTermination"];
        
        _customIfString = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"customIfString"];
        _customThenString = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"customThenString"];
        
        // Setup handling for a reachability change
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(reachabilityChanged:)
                                                     name:kReachabilityChangedNotification
                                                   object:nil];
    }
    
    return self;

}

+ (BOOL)supportsSecureCoding
{
    return YES;
}

@end
