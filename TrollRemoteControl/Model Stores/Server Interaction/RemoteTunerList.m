//
//  RemoteTunerList.m
//  RemoteServerMonitor, TrollRemoteControl
//
//  Created by Pete Maiser on 1/3/16.
//  Copyright © 2016 Pete Maiser. All rights reserved.
//

#import "RemoteTunerList.h"
#import "RemoteTuner.h"
#import "RemoteTunerNAD.h"
#import "RemoteServer.h"

@interface RemoteTunerList ()
@property (nonatomic) NSMutableArray *privateTuners;
@end

@implementation RemoteTunerList

+ (instancetype)sharedList
{
    // As a singleton, make the pointer to the store static so that it will always exist
    static RemoteTunerList *sharedRemoteTunerList;
    
    // Check if the shared store already exists; if not create it
    if (!sharedRemoteTunerList) {
        sharedRemoteTunerList = [[self alloc] initPrivate];
    }
    return sharedRemoteTunerList;
}

- (instancetype)init
{
    // This method should not be used
    [NSException raise:@"Singleton" format:@"Use +[Settings sharedSettings]"];
    return nil;
}

- (instancetype)initPrivate
{
    // This is the real initializer
    self = [super init];
    if (self) {
        
        // Startup the private items
        _privateTuners = [[NSMutableArray alloc] init];
        
        // Try to retrieve saved items
        NSString *path = [self archivePath];
        NSMutableArray *tuners = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
        
        // if there are saved items, load them into the private items,
        // while checking to see if any need to be upgraded
        if (tuners) {
            for (RemoteTuner *rt in tuners) {
                if (rt.modelObjectVersion >= 1) {
                    [_privateTuners addObject:rt];
                } else {
                    RemoteTunerNAD *rtNAD = [[RemoteTunerNAD alloc] initWithRemoteTuner:rt];
                    [_privateTuners addObject:rtNAD];
                }
            }
        }
        
    }
    return self;
}

- (NSArray *)tuners
{
    //Override the getter of the array to return a copy of private items
    return [self.privateTuners copy];
}

- (void)addTuner:(RemoteTuner *)tuner
{
    [self.privateTuners addObject:tuner];
}

- (void)deleteTuner:(RemoteTuner *)tuner
{
    if (tuner) {
        NSUInteger itemIndex = [_privateTuners indexOfObject:tuner];
        if (itemIndex != NSNotFound) {
            [_privateTuners removeObjectAtIndex:itemIndex];
        }
    }
}

- (void)deteleTunersWithServer:(RemoteServer *)server
{
    NSMutableArray *deleteQueue = [[NSMutableArray alloc] init];
    
    for (RemoteTuner *tuner in self.privateTuners) {
        if ([tuner.serverUUID.UUIDString isEqualToString:server.serverUUID.UUIDString]) {
            [deleteQueue addObject:tuner];
        }
    }
    
    for (RemoteTuner *tuner in deleteQueue) {
        [self deleteTuner:tuner];
    }
    
}

- (void)handleString:(NSString *)string
          fromServer:(RemoteServer *)server
{
    for (RemoteTuner *tuner in self.privateTuners) {
        [tuner handleString:string
                fromServer:server];
    }
}

- (RemoteTuner *)getTunerWithServerUUID:(NSUUID *)uuid
{
    RemoteTuner *tuner = nil;
    
    for (RemoteTuner *t in self.privateTuners) {
        if ([t.serverUUID.UUIDString isEqualToString:uuid.UUIDString]) {
            tuner = t;
            break;
        }
    }
    
    return tuner;
}

- (NSString *)archivePath
{
    NSArray *documentDirectories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    NSString *documentDirectory = [documentDirectories firstObject];
    
    NSString *archiveFile = [NSString stringWithFormat:@"%@.tuners.archive", [NSString stringWithUTF8String:getprogname()]];
    
    NSString *archivePath = [documentDirectory stringByAppendingPathComponent:archiveFile];
    
    return archivePath;
}

- (BOOL)saveTuners
{
    NSString *path = [self archivePath];
    
    return [NSKeyedArchiver archiveRootObject:self.privateTuners
                                       toFile:path];
}

@end
