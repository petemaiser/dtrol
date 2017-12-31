//
//  SettingsList.m
//  RemoteServerMonitor, TrollRemoteControl
//
//  Created by Pete Maiser on 1/3/16.
//  Copyright © 2016 Pete Maiser. All rights reserved.
//

#import "SettingsList.h"
#import "Hyperlink.h"
#import "UserPreferences.h"

@interface SettingsList ()

@property (nonatomic) NSMutableArray *privateHyperlinks;

@end

@implementation SettingsList

+ (instancetype)sharedSettingsList
{
    // As a singleton, make the pointer to the store static so that it will always exist
    static SettingsList *sharedSettingsList;
    
    // Check if the shared store already exists; if not create it
    if (!sharedSettingsList) {
        sharedSettingsList = [[self alloc] initPrivate];
    }
    return sharedSettingsList;
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
        
        // First try to retrieve saved settings...each setting at a time
        // If there is no saved setting then setup a default
        
        NSString * pathForHyperlinks = [[self archiveDirectory] stringByAppendingPathComponent:[self archiveFileName:hyperlinksFile]];
        _privateHyperlinks = [NSKeyedUnarchiver unarchiveObjectWithFile:pathForHyperlinks];
        if (!_privateHyperlinks) {
            [self hyperlinksDefaults];
        }
        
        NSString * pathForUserPreferences = [[self archiveDirectory] stringByAppendingPathComponent:[self archiveFileName:userPreferencesFile]];
        _userPreferences = [NSKeyedUnarchiver unarchiveObjectWithFile:pathForUserPreferences];
        if (!_userPreferences) {
            UserPreferences *prefs = [[UserPreferences alloc] init];
            self.userPreferences = prefs;
        }
        
    }
    return self;
}


- (NSArray *)hyperlinks
{
    //Override the getter of the array to return a copy of private items
    return [self.privateHyperlinks copy];
}

- (void)addHyperlink:(Hyperlink *)link
{
    [self.privateHyperlinks addObject:link];
}

- (void)modifyHyperlinkAtIndex:(NSUInteger)itemIndex
                          name:(NSString *)name
                       address:(NSString *)address
{
    Hyperlink *privateLink = self.privateHyperlinks[itemIndex];
    if (name) {
        privateLink.name = name;
    }
    if (address) {
        privateLink.address = address;
    }
}

- (void)moveLinkAtIndex:(NSUInteger)fromIndex
                toIndex:(NSUInteger)toIndex
{
    if (fromIndex == toIndex){
        return;
    }
    
    Hyperlink *link = self.privateHyperlinks[fromIndex];
    [self.privateHyperlinks removeObjectAtIndex:fromIndex];
    if (link) {
        [self.privateHyperlinks insertObject:link atIndex:toIndex];
    }
}

- (void)deleteHyperlink:(Hyperlink *)link
{
    NSUInteger itemIndex = [_privateHyperlinks indexOfObject:link];
    if (itemIndex != NSNotFound) {
        [_privateHyperlinks removeObjectAtIndex:itemIndex];
    }
}

- (void)hyperlinksDefaults
{
    // Load Defaults
    
    NSMutableArray *hyperlinks = [[NSMutableArray alloc] init];
    Hyperlink *hyperlink;
    
    hyperlink = nil;
    hyperlink = [[Hyperlink alloc] init];
    hyperlink.name = @"Pandora";
    hyperlink.address = @"pandora://";
    [hyperlinks addObject:hyperlink];

    hyperlink = nil;
    hyperlink = [[Hyperlink alloc] init];
    hyperlink.name = @"Spotify";
    hyperlink.address = @"spotify://";
    [hyperlinks addObject:hyperlink];

    hyperlink = nil;
    hyperlink = [[Hyperlink alloc] init];
    hyperlink.name = @"Amazon Music";
    hyperlink.address = @"amznmp3://";
    [hyperlinks addObject:hyperlink];
    
    hyperlink = nil;
    hyperlink = [[Hyperlink alloc] init];
    hyperlink.name = @"iHeartRadio";
    hyperlink.address = @"iheartradio://";
    [hyperlinks addObject:hyperlink];
    
    hyperlink = nil;
    hyperlink = [[Hyperlink alloc] init];
    hyperlink.name = @"Netflix";
    hyperlink.address = @"nflx://";
    [hyperlinks addObject:hyperlink];
    
    hyperlink = nil;
    hyperlink = [[Hyperlink alloc] init];
    hyperlink.name = @"Plex";
    hyperlink.address = @"plexapp://";
    [hyperlinks addObject:hyperlink];

    hyperlink = nil;
    hyperlink = [[Hyperlink alloc] init];
    hyperlink.name = @"iTunes";
    hyperlink.address = @"itms://";
    [hyperlinks addObject:hyperlink];
    
    hyperlink = nil;
    hyperlink = [[Hyperlink alloc] init];
    hyperlink.name = @"Videos";
    hyperlink.address = @"videos://";
    [hyperlinks addObject:hyperlink];

    hyperlink = nil;
    hyperlink = [[Hyperlink alloc] init];
    hyperlink.name = @"Remote";
    hyperlink.address = @"remote://";
    [hyperlinks addObject:hyperlink];
    
    self.privateHyperlinks = hyperlinks;
}

- (NSString *)archiveDirectory
{
    NSArray *documentDirectories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    NSString *documentDirectory = [documentDirectories firstObject];
    
    return documentDirectory;
}


- (NSString *)archiveFileName:(NSString *)fileName
{
    return [NSString stringWithFormat:@"%@.%@", [NSString stringWithUTF8String:getprogname()], fileName];
}


- (BOOL)saveSettings
{
    return ([self saveSettingsHyperlinks]&&[self saveSettingsUserPreferences]);
}

- (BOOL)saveSettingsHyperlinks
{
    NSString *path = [[self archiveDirectory] stringByAppendingPathComponent:[self archiveFileName:hyperlinksFile]];
    
    return [NSKeyedArchiver archiveRootObject:self.privateHyperlinks
                                       toFile:path];
}

- (BOOL)saveSettingsUserPreferences
{
    NSString *path = [[self archiveDirectory] stringByAppendingPathComponent:[self archiveFileName:userPreferencesFile]];
    
    return [NSKeyedArchiver archiveRootObject:self.userPreferences
                                       toFile:path];
}

@end
