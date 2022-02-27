//
//  RemoteZoneList.m
//  RemoteServerMonitor, TrollRemoteControl
//
//  Created by Pete Maiser on 1/3/16.
//  Copyright © 2016 Pete Maiser. All rights reserved.
//

#import "RemoteZoneList.h"
#import "RemoteZone.h"
#import "RemoteZoneNAD.h"
#import "RemoteServer.h"
#import "Command.h"
#import "Status.h"
#import "Source.h"


@interface RemoteZoneList ()

@property (nonatomic) NSMutableArray *privateZones;

@end

@implementation RemoteZoneList

+ (instancetype)sharedList
{
    // As a singleton, make the pointer to the store static so that it will always exist
    static RemoteZoneList *sharedRemoteZoneList;
    
    // Check if the shared store already exists; if not create it
    if (!sharedRemoteZoneList) {
        sharedRemoteZoneList = [[self alloc] initPrivate];
    }
    return sharedRemoteZoneList;
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
        _privateZones = [[NSMutableArray alloc] init];
        
        // First try to retrieve saved items
        NSError *error;
        NSData *data = [[NSData alloc] initWithContentsOfFile:[self archivePath]];
        NSSet *classes = [NSSet setWithObjects:[NSMutableArray class]
                                                ,[NSArray class]
                                                ,[NSSet class]
                                                ,[RemoteZone class]
                                                ,[RemoteServer class]
                                                ,[Command class]
                                                ,[Status class]
                                                ,[Source class]
                                                ,[NSString class]
                                                ,nil];
        NSMutableArray *zones = [NSKeyedUnarchiver unarchivedObjectOfClasses:classes fromData:data error:&error];
        
        // if there are saved items, load them into the private items,
        // while checking to see if any need to be upgraded
        if (zones) {
            for (RemoteZone *z in zones) {
                if (z.modelObjectVersion >= 1) {
                    [_privateZones addObject:z];
                } else {
                    RemoteZoneNAD *rzNAD = [[RemoteZoneNAD alloc] initWithRemoteZone:z];
                    [_privateZones addObject:rzNAD];
                }
            }
        }

    }
    return self;
}

- (NSArray *)zones
{
    // Override the getter of the array to return a copy of private items
    return [self.privateZones copy];
}

- (NSArray *)zonesNotHidden
{
    // Build an array that does not contain the hidden zones
    NSMutableArray *znh = [[NSMutableArray alloc] init];
    for (RemoteZone *z in self.privateZones) {
        if (!z.isHidden) {
            [znh addObject:z];
        }
    }
    return [znh copy];
}

- (void)addZone:(RemoteZone *)zone
{
    [self.privateZones addObject:zone];
}

- (void)deleteZone:(RemoteZone *)zone
{   
    if (zone) {
        NSUInteger itemIndex = [_privateZones indexOfObject:zone];
        if (itemIndex != NSNotFound) {
            [_privateZones removeObjectAtIndex:itemIndex];
        }
    }
}

- (void)deteleZonesWithServer:(RemoteServer *)server
{
    NSMutableArray *deleteQueue = [[NSMutableArray alloc] init];
    
    for (RemoteZone *z in self.privateZones) {
        if ([z.serverUUID.UUIDString isEqualToString:server.serverUUID.UUIDString]) {
            [deleteQueue addObject:z];
        }
    }
    
    for (RemoteZone *z in deleteQueue) {
        [self deleteZone:z];
    }
}

- (void)moveItemAtIndex:(NSUInteger)fromIndex
                toIndex:(NSUInteger)toIndex
{
    if (fromIndex == toIndex){
        return;
    }
    
    RemoteZone *zone = self.privateZones[fromIndex];
    [self.privateZones removeObjectAtIndex:fromIndex];
    if (zone) {
        [self.privateZones insertObject:zone atIndex:toIndex];
    }
}

- (void)handleString:(NSString *)string
          fromServer:(RemoteServer *)server
{
    for (RemoteZone *z in self.privateZones) {
        [z handleString:string
                fromServer:server];
    }
}

- (BOOL)validateServer:(RemoteServer *)server
{
    for (RemoteZone *z in self.privateZones) {
        if ([z.serverUUID.UUIDString isEqualToString:server.serverUUID.UUIDString]) {
            return YES;  // A server is "valid" if at least one zone is using it
        }
    }
    return NO;
}

- (RemoteZone *)getZoneWithServerUUID:(NSUUID *)uuid
{
    RemoteZone *zone = nil;
    
    for (RemoteZone *z in self.privateZones) {
        if ([z.serverUUID.UUIDString isEqualToString:uuid.UUIDString]) {
            zone = z;
            break;
        }
    }
    
    return zone;
}

- (RemoteZone *)getZoneWithZoneUUID:(NSUUID *)uuid
{
    RemoteZone *zone = nil;
    
    for (RemoteZone *z in self.privateZones) {
        if ([z.zoneUUID.UUIDString isEqualToString:uuid.UUIDString]) {
            zone = z;
            break;
        }
    }
    
    return zone;
}


- (NSString *)archivePath
{
    NSArray *documentDirectories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    NSString *documentDirectory = [documentDirectories firstObject];
    
    NSString *archiveFile = [NSString stringWithFormat:@"%@.zones.archive", [NSString stringWithUTF8String:getprogname()]];
    
    NSString *archivePath = [documentDirectory stringByAppendingPathComponent:archiveFile];
    
    return archivePath;
}

- (BOOL)saveZones
{
    NSError *error;
    NSData* data = [NSKeyedArchiver archivedDataWithRootObject:self.privateZones requiringSecureCoding:YES error:&error];
    return [data writeToFile:[self archivePath] atomically:YES];
}

@end
