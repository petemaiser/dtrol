//
//  SettingsList.h
//  RemoteServerMonitor, TrollRemoteControl
//
//  Created by Pete Maiser on 1/3/16.
//  Copyright © 2016 Pete Maiser. All rights reserved.
//

#import <Foundation/Foundation.h>
@class Hyperlink;
@class UserPreferences;

@interface SettingsList : NSObject

@property (nonatomic, readonly) NSArray *hyperlinks;
@property (nonatomic) UserPreferences *userPreferences;

+ (instancetype)sharedSettingsList;

- (void)addHyperlink:(Hyperlink *)link;
- (void)modifyHyperlinkAtIndex:(NSUInteger)itemIndex
                   name:(NSString *)name
                address:(NSString *)address;
- (void)moveLinkAtIndex:(NSUInteger)fromIndex
                toIndex:(NSUInteger)toIndex;
- (void)deleteHyperlink:(Hyperlink *)link;

- (BOOL)saveSettings;

#define hyperlinksFile @"settings.hyperlinks.archive"
#define userPreferencesFile @"settings.userPreferences.archive"

@end

