//
//  RemoteServerList.m
//  RemoteServerMonitor, TrollRemoteControl
//
//  Created by Pete Maiser on 1/3/16.
//  Copyright © 2016 Pete Maiser. All rights reserved.
//

#import "RemoteServerList.h"
#import "RemoteServer.h"

@interface RemoteServerList ()
@property (nonatomic) NSMutableArray *privateServers;
@end

@implementation RemoteServerList

+ (instancetype)sharedList
{
    // As a singleton, make the pointer to the store static so that it will always exist
    static RemoteServerList *sharedRemoteServerList;
    
    // Check if the shared store already exists; if not create it
    if (!sharedRemoteServerList) {
        sharedRemoteServerList = [[self alloc] initPrivate];
    }
    return sharedRemoteServerList;
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
        
        ///First try to retrieve saved items
        NSString * path = [self archivePath];
        _privateServers = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
        
        // If there are no saved items then start fresh
        if (!_privateServers) {
            _privateServers = [[NSMutableArray alloc] init];
        }
        
    }
    return self;
}

- (NSArray *)servers
{
    //Override the getter of the array to return a copy of private items
    return [self.privateServers copy];
}

- (void)addServer:(RemoteServer *)server
{
    if (server) {
        [self.privateServers addObject:server];
    }
}

- (void)deleteServer:(RemoteServer *)server
{
    if (server) {
        NSUInteger itemIndex = [_privateServers indexOfObject:server];
        if (itemIndex != NSNotFound) {
            [_privateServers removeObjectAtIndex:itemIndex];
        }
    }
    
    return;
}

- (void)moveItemAtIndex:(NSUInteger)fromIndex
                toIndex:(NSUInteger)toIndex
{
    if (fromIndex == toIndex){
        return;
    }
    
    RemoteServer *server = self.privateServers[fromIndex];
    [self.privateServers removeObjectAtIndex:fromIndex];
    if (server) {
        [self.privateServers insertObject:server atIndex:toIndex];
    }
}

- (RemoteServer *)getServerWithUUID:(NSUUID *)uuid
{
    RemoteServer *server = nil;
    
    for (RemoteServer *s in self.privateServers) {
        if ([s.serverUUID.UUIDString isEqualToString:uuid.UUIDString]) {
            server = s;
            break;
        }
    }
    
    return server;
}

- (NSString *)archivePath
{
    NSArray *documentDirectories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    NSString *documentDirectory = [documentDirectories firstObject];
    
    NSString *archiveFile = [NSString stringWithFormat:@"%@.servers.archive", [NSString stringWithUTF8String:getprogname()]];
    
    NSString *archivePath = [documentDirectory stringByAppendingPathComponent:archiveFile];
    
    return archivePath;
}

- (BOOL)saveServers
{
    NSString *path = [self archivePath];
    
    return [NSKeyedArchiver archiveRootObject:self.privateServers
                                       toFile:path];
}

@end
